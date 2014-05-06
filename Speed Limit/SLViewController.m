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
  
  // load clock
  [self updateClock];
  
  [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)locationDataUpdated:(NSNotification *)notif
{
  // search for a way that is at least 10 meters closer than the currently active way
  NSArray *locations = notif.userInfo[@"locations"];
  CLLocationCoordinate2D currentLocation = [(CLLocation *)locations.lastObject coordinate];
  
  __block CLLocationDistance currentWayDistance = CGFLOAT_MAX;
  if (self.currentWay) {
    currentWayDistance = [self.currentWay distanceFromLocation:currentLocation] - 20;
  }
  
  __weak SLViewController *welf = self;
  [self.speedLimitStore findWayForLocationTrail:locations callback:^(SLWay *way) {
    CLLocationDistance distance = [way distanceFromLocation:currentLocation];
    if (distance > currentWayDistance)
      return;
    
    welf.speedometerView.currentSpeedLimit = way.speedLimit;
    welf.speedLimitView.currentSpeedLimit = way.speedLimit;
    welf.currentStreetLabel.text = way.name;
    welf.currentWay = way;
    currentWayDistance = distance;
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


- (void)updateClock
{
  // set clock to current date
  NSDate *date = [NSDate date];
  NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:date];
  
  self.clockLabel.text = [NSString stringWithFormat:@"%i:%02i", (int)dateComponents.hour, (int)dateComponents.minute];
  
  // find the next second
  NSTimeInterval timeSinceLastSecond = date.timeIntervalSince1970 - floor(date.timeIntervalSince1970);
  NSTimeInterval timeToNextMinute = (60 - dateComponents.second) - timeSinceLastSecond;
  
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeToNextMinute * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self updateClock];
  });
}

@end
