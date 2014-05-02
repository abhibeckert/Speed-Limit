//
//  Speed_LimitTests.m
//  Speed LimitTests
//
//  Created by Abhi Beckert on 25/03/2014.
//
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import <XCTest/XCTest.h>
#import "SLSpeedLimitStore.h"
#import "SLMath.h"

@interface Speed_LimitTests : XCTestCase

@property SLWay *catherineStreet;
@property SLWay *downingStreet;
@property SLWay *parkAvenue;

@end

@implementation Speed_LimitTests

+ (void)setUp
{
  
}

- (void)setUp
{
  [super setUp];
  
  self.catherineStreet = [[SLWay alloc] initWithWayID:42 name:@"Catherine Street" speedLimit:50 nodes:@[@[@-17.3524, @145.5911],
                                                                                                        @[@-17.3526, @145.5911],
                                                                                                        @[@-17.3527, @145.5912],
                                                                                                        @[@-17.3528, @145.5914]]];
  
  self.downingStreet = [[SLWay alloc] initWithWayID:42 name:@"Downing Street" speedLimit:50 nodes:@[@[@-17.3530, @145.5910],
                                                                                                    @[@-17.3524, @145.5911],
                                                                                                    @[@-17.3520, @145.5911],
                                                                                                    @[@-17.3518, @145.5910]]];
  
  self.parkAvenue = [[SLWay alloc] initWithWayID:42 name:@"Park Avenue" speedLimit:60 nodes:@[@[@-17.3521, @145.5898],
                                                                                              @[@-17.3518, @145.5910],
                                                                                              @[@-17.3515, @145.5917]]];
}

- (void)tearDown
{
  
  [super tearDown];
}

- (void)testBasicWayLocationComparison
{
  CLLocationCoordinate2D nearCatherineAndDowning = CLLocationCoordinate2DMake(-17.3525, 145.5911);
  NSArray *nearCatherineAndDowningTrail = @[@[[NSNumber numberWithDouble:nearCatherineAndDowning.latitude],
                                              [NSNumber numberWithDouble:nearCatherineAndDowning.longitude]]];
  
  XCTAssertTrue([self.catherineStreet matchesLocation:nearCatherineAndDowning trail:nearCatherineAndDowningTrail]);
  XCTAssertTrue([self.downingStreet matchesLocation:nearCatherineAndDowning trail:nearCatherineAndDowningTrail]);
  XCTAssertFalse([self.parkAvenue matchesLocation:nearCatherineAndDowning trail:nearCatherineAndDowningTrail]);
}

- (void)testDistanceToStreet
{
  CLLocationCoordinate2D location = CLLocationCoordinate2DMake(-17.3525, 145.5914);
  
  XCTAssertEqualWithAccuracy([self.catherineStreet distanceFromLocation:location], 29.81, 0.1);
  XCTAssertEqualWithAccuracy([self.downingStreet distanceFromLocation:location], 34.71, 0.1);
  XCTAssertEqualWithAccuracy([self.parkAvenue distanceFromLocation:location], 89.00, 0.1);
}

@end
