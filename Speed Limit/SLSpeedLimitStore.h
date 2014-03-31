//
//  SLSpeedLimitStore.h
//  Speed Limit
//
//  Created by Abhi Beckert on 27/03/2014.
//  Copyright (c) 2014 Abhi Beckert. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SLWay.h"

@interface SLSpeedLimitStore : NSObject

- (instancetype)initWithStorageURL:(NSURL *)url;

@property (readonly, strong) NSURL *storageUrl;

- (void)findWayForLocationTrail:(NSArray *)locations callback:(void (^)(SLWay *way))callback;

- (NSArray *)allWays;

@end
