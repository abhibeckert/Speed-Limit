//
//  SLViewController.h
//  Speed Limit
//
//  Created by Abhi Beckert on 25/03/2014.
//  Copyright (c) 2014 Abhi Beckert. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLSpeedometerView.h"
#import "SLSpeedLimitView.h"

@interface SLViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *currentStreetLabel;
@property (weak, nonatomic) IBOutlet SLSpeedometerView *speedometerView;
@property (weak, nonatomic) IBOutlet SLSpeedLimitView *speedLimitView;

@end
