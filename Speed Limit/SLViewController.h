//
//  SLViewController.h
//  Speed Limit
//
//  Created by Abhi Beckert on 25/03/2014.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import <UIKit/UIKit.h>
#import "SLSpeedometerView.h"
#import "SLSpeedLimitView.h"

@interface SLViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *currentStreetLabel;
@property (weak, nonatomic) IBOutlet SLSpeedometerView *speedometerView;
@property (weak, nonatomic) IBOutlet SLSpeedLimitView *speedLimitView;
@property (weak, nonatomic) IBOutlet UILabel *clockLabel;

@end
