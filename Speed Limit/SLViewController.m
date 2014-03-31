//
//  SLViewController.m
//  Speed Limit
//
//  Created by Abhi Beckert on 25/03/2014.
//  Copyright (c) 2014 Abhi Beckert. All rights reserved.
//

#import "SLViewController.h"
#import "SLSpeedLimitStore.h"

@interface SLViewController ()

@property NSArray *speedLimitStores;

@end

@implementation SLViewController

- (void)viewDidLoad
{
  // monitor speed updates
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationDataUpdated:) name:@"SLLocationDataUpdated" object:nil];
  
  // load speed limit stores
  self.speedLimitStores = @[];
  NSURL *documentsUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
  NSDirectoryEnumerator *documentsEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:documentsUrl includingPropertiesForKeys:nil options:0 errorHandler:NULL];
  for (NSURL *childUrl in documentsEnumerator) {
    if (![childUrl.pathExtension isEqualToString:@"slw"])
      continue;
    
    SLSpeedLimitStore *store = [[SLSpeedLimitStore alloc] initWithStorageURL:childUrl];
    self.speedLimitStores = [self.speedLimitStores arrayByAddingObject:store];
  }
  
  [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)locationDataUpdated:(NSNotification *)notif
{
  NSDictionary *details = notif.userInfo;
  
//  self.currentStreetLabel.text = [NSString stringWithFormat:@"speed: %@ avg: %@ variation: %@", details[@"currentSpeed"], details[@"averageSpeed"], details[@"averageChange"]];
  
  
  for (SLSpeedLimitStore *store in self.speedLimitStores) {
    [store findWayForLocationTrail:details[@"locations"] callback:^(SLWay *way) {
      self.speedometerView.currentSpeedLimit = way.speedLimit;
      self.speedLimitView.currentSpeedLimit = way.speedLimit;
      self.currentStreetLabel.text = way.name;
    }];
  }
}

@end
