//
//  SLSpeedLimitStore.m
//  Speed Limit
//
//  Created by Abhi Beckert on 27/03/2014.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "SLSpeedLimitStore.h"
#import <CoreLocation/CoreLocation.h>
#import "NSData+SLNSDataCompression.h"

@interface SLSpeedLimitStore ()

@property NSURL *storageUrl;
@property NSCache *waysCache;

@end

@implementation SLSpeedLimitStore

- (instancetype)init
{
  return [self initWithStorageURL:nil];
}

- (instancetype)initWithStorageURL:(NSURL *)url
{
  if (!(self = [super init]))
    return nil;
  
  self.storageUrl = url;
  self.waysCache = [[NSCache alloc] init];
  self.waysCache.countLimit = 4;
  
  return self;
}

- (void)findWayForLocationTrail:(NSArray *)locations callback:(void (^)(SLWay *way))callback
{
  NSArray *ways = [self waysForLocationTrail:locations];
  
  if (!ways) {
    return;
  }
  
  CLLocationCoordinate2D currentCoord = [(CLLocation *)locations.lastObject coordinate];
  
  __block BOOL foundWay = NO;
  
  [ways enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(SLWay *way, NSUInteger idx, BOOL *stop) {
    if (![way matchesLocation:currentCoord trail:locations])
      return;
    
    *stop = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
      if (foundWay)
        return;
      foundWay = YES;
      
      callback(way);
    });
  }];
}

- (NSArray *)waysForLocationTrail:(NSArray *)locations
{
  CLLocationCoordinate2D currentCoord = [(CLLocation *)locations.lastObject coordinate];
  
  NSUInteger fileLat = floor(currentCoord.latitude + 180);
  NSUInteger fileLon = floor(currentCoord.longitude + 180);
  
  NSString *filename = [NSString stringWithFormat:@"%i_%i.slw.gz", (int)fileLat - 180, (int)fileLon - 180];
  NSArray *ways = [self.waysCache objectForKey:filename];
  if (ways)
    return ways;
  
  NSURL *localFileUrl = [self.storageUrl URLByAppendingPathComponent:filename];
  NSData *fileData = [NSData dataWithContentsOfURL:localFileUrl];
  fileData = [fileData gzipInflate];
  
  if (!fileData) {
    static NSDate *lastDownloadDate = nil;
    
    // if there is no last download date, or if it's more than 2 minutes ago, try downloading from the remote server
    if (!lastDownloadDate || [lastDownloadDate timeIntervalSinceNow] < 120) {
      lastDownloadDate = [NSDate date];
      [[NSNotificationCenter defaultCenter] postNotificationName:@"SLSpeedLimitStoreBeginDownload" object:self userInfo:nil];
      
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *remoteURL = [[NSURL URLWithString:@"http://abhibeckert.com/speed-limit.sld"] URLByAppendingPathComponent:filename];
        NSData *remoteData = [NSData dataWithContentsOfURL:remoteURL];
        [remoteData writeToURL:localFileUrl options:NSDataWritingAtomic error:NULL];
        
        dispatch_async(dispatch_get_main_queue(), ^{
          [[NSNotificationCenter defaultCenter] postNotificationName:@"SLSpeedLimitStoreFinishedDownload" object:self userInfo:@{@"success": remoteData ? @YES : @NO}];
        });
      });
    }
    
    return nil;
  }
  
  ways = [NSKeyedUnarchiver unarchiveObjectWithData:fileData];
  
  [self.waysCache setObject:ways forKey:filename];
  return ways;
}

- (NSArray *)allWays
{
  return nil;
}

@end
