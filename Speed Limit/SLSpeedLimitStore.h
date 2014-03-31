//
//  SLSpeedLimitStore.h
//  Speed Limit
//
//  Created by Abhi Beckert on 27/03/2014.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import <Foundation/Foundation.h>

#import "SLWay.h"

@interface SLSpeedLimitStore : NSObject

- (instancetype)initWithStorageURL:(NSURL *)url;

@property (readonly, strong) NSURL *storageUrl;

- (void)findWayForLocationTrail:(NSArray *)locations callback:(void (^)(SLWay *way))callback;

- (NSArray *)allWays;

@end
