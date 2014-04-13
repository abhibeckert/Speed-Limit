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

@interface SLSpeedLimitStore ()

@property NSURL *storageUrl;
@property NSArray *ways;

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
  
  __weak typeof(self) welf = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    
    NSArray *ways = [NSKeyedUnarchiver unarchiveObjectWithFile:self.storageUrl.path];
    dispatch_sync(dispatch_get_main_queue(), ^{
      welf.ways = ways;
    });
  });
  
  return self;
}

- (void)findWayForLocationTrail:(NSArray *)locations callback:(void (^)(SLWay *way))callback
{
  if (!self.ways)
    return;
  
  CLLocationCoordinate2D currentCoord = [(CLLocation *)locations.lastObject coordinate];
  
  __block BOOL foundWay = NO;
  
  [self.ways enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(SLWay *way, NSUInteger idx, BOOL *stop) {
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

- (NSArray *)allWays
{
  return nil;
}

@end
