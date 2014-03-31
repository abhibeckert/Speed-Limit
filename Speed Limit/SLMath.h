//
//  SLMath.h
//  Speed Limit
//
//  Created by Abhi Beckert on 30/03/2014.
//  Copyright (c) 2014 Abhi Beckert. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#ifndef Speed_Limit_SLMath_h
#define Speed_Limit_SLMath_h

double degreesToRadians(double degrees);
double radiansToDegrees(double radians);

double distanceToCoord(CLLocationCoordinate2D coord1, CLLocationCoordinate2D coord2);
double bearingToCoord(CLLocationCoordinate2D coord1, CLLocationCoordinate2D coord2);

#endif
