//
//  SLWay.h
//  Speed Limit
//
//  Created by Abhi Beckert on 27/03/2014.
//  Copyright (c) 2014 Abhi Beckert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SLWay : NSObject <NSCoding>

- (instancetype)initWithWayID:(NSUInteger)wayId name:(NSString *)name speedLimit:(NSUInteger)speed nodes:(NSArray *)nodes;

@property (readonly) NSUInteger wayId;
@property (readonly) NSString *name;
@property (readonly) NSUInteger speedLimit;

- (BOOL)matchesLocation:(CLLocationCoordinate2D)location trail:(NSArray *)locations;

@end
