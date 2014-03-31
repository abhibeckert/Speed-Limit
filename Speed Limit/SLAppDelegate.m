//
//  SLAppDelegate.m
//  Speed Limit
//
//  Created by Abhi Beckert on 25/03/2014.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "SLAppDelegate.h"
#import <CoreLocation/CoreLocation.h>

@interface SLAppDelegate () <CLLocationManagerDelegate>

@property (strong) CLLocationManager *locationManager;
@property (strong) NSMutableArray *recentLocations;

@end

@implementation SLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
  self.locationManager.delegate = self;
  
  self.recentLocations = @[].mutableCopy;
  
  return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  [self.locationManager startUpdatingLocation];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  [self.locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
  // add locations
  [self.recentLocations addObjectsFromArray:locations];
  
  // kill "old" locations
  [self.recentLocations filterUsingPredicate:[NSPredicate predicateWithFormat:@"self.timestamp.timeIntervalSinceNow > -10.5"]];
  
  // mine some data
  NSTimeInterval timeInterval = [[(CLLocation *)self.recentLocations.lastObject timestamp] timeIntervalSinceDate:[(CLLocation *)self.recentLocations.firstObject timestamp]];
  CGFloat currentSpeed = [(CLLocation *)self.recentLocations.lastObject speed];
  
  CGFloat totalSpeed = 0;
  CGFloat totalChange = 0;
  
  CLLocation *lastLocation = nil;
  for (CLLocation *location in self.recentLocations) {
    totalSpeed += location.speed;
    
    if (lastLocation)
      totalChange += fabs(lastLocation.speed - location.speed);
    
    lastLocation = location;
  }
  CGFloat averageSpeed = totalSpeed / self.recentLocations.count;
  CGFloat averageChange = totalChange / (self.recentLocations.count - 1);
  
  // send out update notification
  NSDictionary *userInfo = @{@"currentSpeed": [NSNumber numberWithFloat:currentSpeed],
                             @"averageSpeed": [NSNumber numberWithFloat:averageSpeed],
                             @"averageChange": [NSNumber numberWithFloat:averageChange],
                             @"timeInterval": [NSNumber numberWithFloat:timeInterval],
                             @"locations": self.recentLocations};
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"SLLocationDataUpdated" object:self userInfo:userInfo];
}

@end
