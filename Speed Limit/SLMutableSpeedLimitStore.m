//
//  SLMutableSpeedLimitStore.m
//  Speed Limit
//
//  Created by Abhi Beckert on 27/03/2014.
//  Copyright (c) 2014 Abhi Beckert. All rights reserved.
//

#import "SLMutableSpeedLimitStore.h"

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
  
  // write contents
  [NSKeyedArchiver archiveRootObject:self.mutableWays toFile:[url.path stringByAppendingPathComponent:@"ways.slw"]];
}

@end
