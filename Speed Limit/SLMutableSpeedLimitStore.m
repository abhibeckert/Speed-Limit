//
//  SLMutableSpeedLimitStore.m
//  Speed Limit
//
//  Created by Abhi Beckert on 27/03/2014.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "SLMutableSpeedLimitStore.h"
#import "NSData+SLNSDataCompression.h"

@interface SLMutableSpeedLimitStore()

@property (strong) NSMutableArray *mutableWays;

@end

@implementation SLMutableSpeedLimitStore

- (instancetype)initWithStorageURL:(NSURL *)url
{
  if (!(self = [super initWithStorageURL:url]))
    return nil;
  
  self.mutableWays = [[NSMutableArray alloc] init];
  
  return self;
}

- (void)addWay:(SLWay *)way
{
  [self.mutableWays addObject:way];
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<SLMutableSpeedLimitStore %@> (%lu ways)", self.storageUrl, self.mutableWays.count];
}

- (NSArray *)allWays
{
  return self.mutableWays;
}

- (void)writeToUrl:(NSURL *)url
{
  NSFileManager *fman = [NSFileManager defaultManager];
  
  // trash existing file
  if ([url checkResourceIsReachableAndReturnError:NULL]) {
    [fman removeItemAtURL:url error:NULL];
  }
  
  // create bundle
  [fman createDirectoryAtURL:url withIntermediateDirectories:NO attributes:nil error:NULL];
  
  // figure out which coordinates (with no decimal places, and adding 180 to avoid negative values) will have some data in them
  BOOL filesWithData[360][360] = {0};
  for (SLWay *way in self.mutableWays) {
    CLLocationCoordinate2D minCoord = way.minCoord;
    NSUInteger minFileLat = floor(minCoord.latitude + 180);
    NSUInteger minFileLon = floor(minCoord.longitude + 180);
    
    CLLocationCoordinate2D maxCoord = way.maxCoord;
    NSUInteger maxFileLat = floor(maxCoord.latitude + 180);
    NSUInteger maxFileLon = floor(maxCoord.longitude + 180);
    
    NSUInteger fileLat = minFileLat;
    NSUInteger fileLon = minFileLon;
    while (fileLat <= maxFileLat) {
      while (fileLon <= maxFileLon) {
        filesWithData[fileLat][fileLon] = YES;
        fileLon++;
      }
      fileLat++;
      fileLon = minFileLon;
    }
  }
  
  // write out the data
  for (NSInteger fileLat = 0; fileLat < 360; fileLat++) {
    for (NSInteger fileLon = 0; fileLon < 360; fileLon++) {
      if (!filesWithData[fileLat][fileLon])
        continue; // no data for this coord
      
      @autoreleasepool {
        NSMutableArray *fileWays = [NSMutableArray array];
        
        for (SLWay *way in self.mutableWays) {
          // load bounds for this way
          CLLocationCoordinate2D minCoord = way.minCoord;
          NSInteger minFileLat = floor(minCoord.latitude + 180);
          NSInteger minFileLon = floor(minCoord.longitude + 180);
          
          CLLocationCoordinate2D maxCoord = way.maxCoord;
          NSInteger maxFileLat = floor(maxCoord.latitude + 180);
          NSInteger maxFileLon = floor(maxCoord.longitude + 180);
          
          // check if way is included in file
          if (maxFileLat < fileLat)
            continue;
          if (maxFileLon < fileLon)
            continue;
          if (minFileLat > fileLat)
            continue;
          if (minFileLon > fileLon)
            continue;
          
          [fileWays addObject:way];
        }
        
        NSString *filename = [NSString stringWithFormat:@"%i_%i.slw.gz", (int)fileLat - 180, (int)fileLon - 180];
        NSData *fileData = [[NSKeyedArchiver archivedDataWithRootObject:fileWays] gzipDeflate];
        
        [fileData writeToURL:[url URLByAppendingPathComponent:filename] atomically:YES];
      }
    }
  }
}

@end
