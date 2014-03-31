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

@interface SLOSMImporter () <NSXMLParserDelegate>

@property (strong) SLMutableSpeedLimitStore *store;
@property (strong) NSURL *url;

@property (strong) NSXMLParser *parser;

@property (strong) NSMutableDictionary *parserAllNodes;
@property (strong) NSMutableDictionary *parserCurrentWay;

@end

@implementation SLOSMImporter

- (instancetype)initWithStore:(SLMutableSpeedLimitStore *)store importURL:(NSURL *)url
{
  if (!(self = [super init]))
    return nil;
  
  self.store = store;
  self.url = url;
  
  return self;
}

- (void)import
{
  self.parser = [[NSXMLParser alloc] initWithContentsOfURL:self.url];
  self.parser.delegate = self;
  
  [self.parser parse];
  
  self.parser = nil;
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
    return;
  }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
  if ([elementName isEqualToString:@"way"]) {
    NSUInteger speed = [(NSString *)self.parserCurrentWay[@"speed"] integerValue];
//    if (speed != 0) {
      NSUInteger wayId = [(NSString *)self.parserCurrentWay[@"id"] integerValue];
      
      NSMutableArray *nodes = [NSMutableArray array];
      [self.parserCurrentWay[@"nodes"] enumerateObjectsUsingBlock:^(NSNumber *nodeId, NSUInteger idx, BOOL *stop) {
        [nodes addObject:self.parserAllNodes[nodeId]];
      }];
      
      SLWay *way = [[SLWay alloc] initWithWayID:wayId name:self.parserCurrentWay[@"name"] speedLimit:speed nodes:nodes];
      
      [self.store addWay:way];
//    }
    self.parserCurrentWay = nil;
    return;
  }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
  NSLog(@"XML PARSE ERROR: %@", parseError);
}

@end
