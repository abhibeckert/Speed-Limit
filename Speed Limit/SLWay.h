//
//  SLWay.h
//  Speed Limit
//
//  Created by Abhi Beckert on 27/03/2014.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import <Foundation/Foundation.h>

@interface SLWay : NSObject <NSCoding>

- (instancetype)initWithWayID:(NSUInteger)wayId name:(NSString *)name speedLimit:(NSUInteger)speed nodes:(NSArray *)nodes;

@property (readonly) NSUInteger wayId;
@property (readonly) NSString *name;
@property (readonly) NSUInteger speedLimit;

@property (nonatomic) NSArray *nodes;
@property (readonly) CLLocationCoordinate2D minCoord;
@property (readonly) CLLocationCoordinate2D maxCoord;

- (BOOL)matchesLocation:(CLLocationCoordinate2D)location trail:(NSArray *)locations;

- (CLLocationDistance)distanceFromLocation:(CLLocationCoordinate2D)location;

@end
