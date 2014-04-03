//
//  SLOSMImporter.m
//  Speed Limit
//
//  Created by Abhi Beckert on 27/03/2014.
//
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "SLOSMImporter.h"

#include <stdio.h>

// http://stackoverflow.com/questions/1044334/objective-c-reading-a-file-line-by-line
NSString *readLineAsNSString(FILE *file)
{
  char buffer[4096]; // 4KiB
  
  // tune this capacity to your liking -- larger buffer sizes will be faster, but
  // use more memory
  NSMutableString *result = [NSMutableString stringWithCapacity:256];
  
  // Read up to 4096 non-newline characters, then read and discard the newline
  int charsRead;
  do
  {
    if(fscanf(file, "%4095[^\r\n]%n%*[\n\r]", buffer, &charsRead) == 1)
      [result appendFormat:@"%s", buffer];
    else
      break;
  } while(charsRead == 4096); // 4KiB
  
  return result;
}

@interface SLOSMImporter () <NSXMLParserDelegate>

@property SLMutableSpeedLimitStore *store;
@property NSURL *url;

@property NSXMLParser *parser;

@property NSMutableDictionary *parserAllNodes;
@property NSMutableDictionary *parserCurrentWay;

@property (nonatomic, copy) void (^progressCallback)(float progress);
@property NSInteger progressTotalLineCount;

@end

@implementation SLOSMImporter

- (instancetype)initWithStore:(SLMutableSpeedLimitStore *)store importURL:(NSURL *)url
{
  if (!(self = [super init]))
    return nil;
  
  self.store = store;
  self.countWaysWithSpeedLimit = 0;
  self.url = url;
  
  return self;
}

- (void)importWithCompletion:(void (^)())completionCallback progressUpdates:(void (^)(float progress))progressCallback
{
  self.progressCallback = progressCallback;
  
  // map file contents into virtual memory
  NSData *parserData = [NSData dataWithContentsOfURL:self.url options:NSDataReadingMappedAlways error:NULL];
  
  self.parser = [[NSXMLParser alloc] initWithData:parserData];
  self.parser.delegate = self;
  
  // count how many lines there are
  self.progressTotalLineCount = -1;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{

    // iterate through the data in 10KB chunks, counting how many newlines there are
    NSUInteger lineCount = 0;
    NSUInteger byteOffset = 0;
    NSUInteger bytesLength = parserData.length;
    while (byteOffset < bytesLength) {
      NSUInteger chunkOffset = 0;
      NSUInteger chunkLength = MIN(parserData.length - byteOffset, 10000);
      UInt8 chunkBytes[chunkLength];
      [parserData getBytes:&chunkBytes range:NSMakeRange(byteOffset, chunkLength)];
      
      for (chunkOffset = 0; chunkOffset < chunkLength; chunkOffset++) {
        UInt8 character = chunkBytes[chunkOffset];
        
        // classic mac or windows newline
        if (character == '\r') {
          lineCount++;
          
          // windows newline
          if (chunkOffset + 1 < chunkLength) {
            if (chunkBytes[chunkOffset + 1] == '\n') {
              byteOffset++;
            }
          }
          continue;
        }
        
        // modern mac or unix newline
        if (character == '\n') {
          lineCount++;
          continue;
        }
      }
      byteOffset += chunkLength;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
      self.progressTotalLineCount = lineCount;
    });
  });
  
  // parse the data
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // parse data
    [self.parser parse];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      self.parser = nil;
      
      progressCallback(1.0);
      completionCallback();
    });
  });
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
  self.parserCurrentWay = nil;
  self.parserAllNodes = [NSMutableDictionary dictionary];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
  self.parserCurrentWay = nil;
  self.parserAllNodes = nil;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
  static NSDate *lastProgressUpdate = nil;
  if (!lastProgressUpdate || [lastProgressUpdate timeIntervalSinceNow] < -0.5) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.progressTotalLineCount != -1)
        self.progressCallback((float)self.parser.lineNumber / (float)self.progressTotalLineCount);
    });
    lastProgressUpdate = [NSDate date];
  }
  
  
  if ([elementName isEqualToString:@"node"]) {
    self.parserAllNodes[attributeDict[@"id"]] = @[attributeDict[@"lat"], attributeDict[@"lon"]];
    return;
  }
  
  if ([elementName isEqualToString:@"way"]) {
    self.parserCurrentWay = @{@"id": attributeDict[@"id"],
                              @"nodes": @[].mutableCopy,
                              @"name": @"",
                              @"speed": @"0"}.mutableCopy;
    return;
  }
  
  if ([elementName isEqualToString:@"nd"]) {
    [(NSMutableArray *)self.parserCurrentWay[@"nodes"] addObject:attributeDict[@"ref"]];
    return;
  }
  
  if ([elementName isEqualToString:@"tag"]) {
    if ([attributeDict[@"k"] isEqual:@"maxspeed"]) {
      self.parserCurrentWay[@"speed"] = attributeDict[@"v"];
      return;
    }
    if ([attributeDict[@"k"] isEqual:@"name"]) {
      self.parserCurrentWay[@"name"] = attributeDict[@"v"];
      return;
    }
    if ([attributeDict[@"k"] isEqual:@"highway"]) {
      self.parserCurrentWay[@"highway"] = attributeDict[@"v"];
    }
    return;
  }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
  if ([elementName isEqualToString:@"way"]) {
    NSUInteger speed = [(NSString *)self.parserCurrentWay[@"speed"] integerValue];
    NSUInteger wayId = [(NSString *)self.parserCurrentWay[@"id"] integerValue];
    NSString *wayType = self.parserCurrentWay[@"highway"];
    
    static NSSet *validTypes = nil;
    static NSSet *ignoredTypes = nil;
    if (!validTypes) {
      validTypes = [NSSet setWithObjects:@"motorway", @"trunk", @"primary", @"secondary", @"tertiary", @"unclassified", @"road", @"residential", @"service", @"services", @"living_street", @"raceway", @"motorway_link", @"trunk_link", @"primary_link", @"secondary_link", @"tertiary_link", @"construction", @"proposed", nil];
      ignoredTypes = [NSSet setWithObjects:@"cycleway", @"path", @"footway", @"pedestrian", @"steps", @"track", @"crossing", @"bridleway", @"bus_stop", @"disused", @"platform", nil];
    }
    
    // skip the way if it's an ignored highway type, and the speed limit is 30 or less (bicycle paths can have speed limits)
    if (speed <= 30 && (!wayType || [ignoredTypes containsObject:wayType])) {
      self.parserCurrentWay = nil;
      return;
    }
    
    NSMutableArray *nodes = [NSMutableArray array];
    [self.parserCurrentWay[@"nodes"] enumerateObjectsUsingBlock:^(NSNumber *nodeId, NSUInteger idx, BOOL *stop) {
      [nodes addObject:self.parserAllNodes[nodeId]];
    }];
    
    if (![validTypes containsObject:wayType]) {
      if (speed == 0) {
        NSLog(@"SKIPPING way '%@' with invalid highway value '%@' and no speed limit. location: %@, %@.", self.parserCurrentWay[@"name"], wayType, nodes[0][0], nodes[0][1]);
      } else {
        NSLog(@"INCLUDING way '%@' with invalid highway value '%@', and speed limit %i. location: %@, %@.", self.parserCurrentWay[@"name"], wayType, (int)speed, nodes[0][0], nodes[0][1]);
      }
    }
    
    SLWay *way = [[SLWay alloc] initWithWayID:wayId name:self.parserCurrentWay[@"name"] speedLimit:speed nodes:nodes];
    
    [self.store addWay:way];
    if (speed)
      self.countWaysWithSpeedLimit = self.countWaysWithSpeedLimit + 1;
    self.parserCurrentWay = nil;
    return;
  }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
  NSLog(@"XML PARSE ERROR: %@", parseError);
}

@end
