//
//  SLViewController.m
//  Speed Limit
//
//  Created by Abhi Beckert on 25/03/2014.
//
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "SLViewController.h"
#import "SLSpeedLimitStore.h"

@interface SLViewController ()

@property SLSpeedLimitStore *speedLimitStore;
@property SLWay *currentWay;

@end

@implementation SLViewController

- (void)viewDidLoad
{
  // monitor speed updates
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationDataUpdated:) name:@"SLLocationDataUpdated" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeBeginDownload:) name:@"SLSpeedLimitStoreBeginDownload" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeFinishDownload:) name:@"SLSpeedLimitStoreFinishedDownload" object:nil];
  
  // load speed limit store
  NSURL *storeUrl = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"store.sld"];
  if (![storeUrl checkResourceIsReachableAndReturnError:NULL]) {
    [[NSFileManager defaultManager] createDirectoryAtURL:storeUrl withIntermediateDirectories:YES attributes:@{} error:NULL];
  }
  self.speedLimitStore = [[SLSpeedLimitStore alloc] initWithStorageURL:storeUrl];
  
  [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)locationDataUpdated:(NSNotification *)notif
{
  NSArray *locations = notif.userInfo[@"locations"];
  
  //  locations = @[[[CLLocation alloc] initWithLatitude:-17.51716 longitude:145.60797]]; // millaa millaa malanda road
  
  // if we have a away, and it has a speed limit, then check if we're still inside that way.
  if (self.currentWay && self.currentWay.speedLimit != 0) {
    if ([self.currentWay matchesLocation:[(CLLocation *)locations.lastObject coordinate] trail:locations])
      return;
  }
  //  self.currentStreetLabel.text = [locations.lastObject description]; // uncomment this to show lat/lon whenever the a way cannot be found
  
  // find way
  [self.speedLimitStore findWayForLocationTrail:locations callback:^(SLWay *way) {
    self.speedometerView.currentSpeedLimit = way.speedLimit;
    self.speedLimitView.currentSpeedLimit = way.speedLimit;
    self.currentStreetLabel.text = way.name;
    self.currentWay = way;
  }];
}

- (void)storeBeginDownload:(NSNotification *)notif
{
  if (![self.currentStreetLabel.text isEqualToString:@"Unable to download map data"])
    self.currentStreetLabel.text = @"Downloading map data © OpenStreetMap.org";
}

- (void)storeFinishDownload:(NSNotification *)notif
{
  if (![notif.userInfo[@"success"] boolValue]) {
    self.currentStreetLabel.text = @"Unable to download map data";
  }
}

@end
