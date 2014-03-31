//
//  SLSpeedometerView.m
//  Speed Limit
//
//  Created by Abhi Beckert on 25/03/2014.
//  Copyright (c) 2014 Abhi Beckert. All rights reserved.
//

#import "SLSpeedometerView.h"

CGFloat DegreesToRadians(CGFloat degrees)
{
  return degrees * M_PI / 180;
}

NSNumber* DegreesToNumber(CGFloat degrees)
{
  return [NSNumber numberWithFloat:DegreesToRadians(degrees)];
}

const CGFloat minPositionDegrees = 40; // the number of degrees for the "0" position of the needle, rotated from the bottom of the circle
const CGFloat maxPositionDegrees = 320;
const CGFloat maxSpeed = 140;
const CGFloat speedDegreeRatio = 2.0; // 1kmh == 2 degrees

static CGFloat layerContentsScale;

@interface SLSpeedometerView ()

@property (strong) CAShapeLayer *backgroundCircleLayer;
@property (strong) CAShapeLayer *outerRingLayer;
@property (strong) CAShapeLayer *outerRingOverSpeedLayer;
@property (strong) NSArray *speedMarkerLayers;
@property (strong) CALayer *needleLayer;
@property (strong) CAShapeLayer *centerPointLayer;
@property (strong) CATextLayer *currentSpeedLabel;
@property (strong) CALayer *superviewOverSpeedLayer;

@end

@implementation SLSpeedometerView

+ (void)initialize
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    layerContentsScale = [[UIScreen mainScreen] scale];
  });
}

- (void)awakeFromNib
{
  self.backgroundColor = [UIColor clearColor];
  
  CGFloat radius = floor(MIN(CGRectGetWidth(self.frame), CGRectGetWidth(self.frame)) / 2.0) - 2;
  CGPoint centerPoint = CGPointMake(CGRectGetWidth(self.frame) / 2, CGRectGetHeight(self.frame) / 2);
  CGFloat lineWidth = radius / 40;
  CGFloat inset = lineWidth / 2.0;
  UIFont *markerFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:ceil(radius / 7)];
  UIFont *currentSpeedFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:ceil(radius / 3.5)];
  CGFloat majorMarkerDegreesDelta = 1.25;
  CGFloat minorMarkerDegreesDelta = 0.75;
  
  
  // white circle background, so we're always on a white backdrop
  self.backgroundCircleLayer = [CAShapeLayer layer];
  UIBezierPath *path = [UIBezierPath bezierPath];
  [path moveToPoint:centerPoint];
  [path addArcWithCenter:centerPoint radius:radius + (lineWidth * 2) startAngle:0.0 endAngle:M_PI * 2.0 clockwise:YES];
  [path closePath];
  self.backgroundCircleLayer.path = path.CGPath;
  self.backgroundCircleLayer.fillColor = [UIColor whiteColor].CGColor;
  [self.layer addSublayer:self.backgroundCircleLayer];
  
  // black outer ring for the speedometer, just a rounded rect with a black stroke
  self.outerRingLayer = [CAShapeLayer layer];
  path = [UIBezierPath bezierPath];
  [path addArcWithCenter:centerPoint radius:radius startAngle:DegreesToRadians(minPositionDegrees + 90 - (majorMarkerDegreesDelta - 0.1)) endAngle:DegreesToRadians(maxPositionDegrees + 90 + (majorMarkerDegreesDelta - 0.1)) clockwise:YES];
  self.outerRingLayer.path = path.CGPath;
  self.outerRingLayer.fillColor = [UIColor clearColor].CGColor;
  self.outerRingLayer.strokeColor = [UIColor blackColor].CGColor;
  self.outerRingLayer.lineWidth = lineWidth;
  [self.layer addSublayer:self.outerRingLayer];
  
  // red outer ring for the over speed limit part of the speedometer
  self.outerRingOverSpeedLayer = [CAShapeLayer layer];
  path = [UIBezierPath bezierPath];
  [path addArcWithCenter:centerPoint radius:radius startAngle:DegreesToRadians(minPositionDegrees + 90 - (majorMarkerDegreesDelta - 0.1)) endAngle:DegreesToRadians(maxPositionDegrees + 90 + (majorMarkerDegreesDelta - 0.1)) clockwise:YES];
  self.outerRingOverSpeedLayer.path = path.CGPath;
  self.outerRingOverSpeedLayer.fillColor = [UIColor clearColor].CGColor;
  self.outerRingOverSpeedLayer.strokeColor = [UIColor redColor].CGColor;
  self.outerRingOverSpeedLayer.lineWidth = lineWidth;
  self.outerRingOverSpeedLayer.strokeStart = 1.0;
  [self.layer addSublayer:self.outerRingOverSpeedLayer];

  
  // markers along the speed limit every 10kmh, a rectangle rotated based on the speed. even numbered markers are bigger and have a text label
  NSMutableArray *speedMarkerLayers = [NSMutableArray array];
  NSUInteger markerSpeed = 0;
  for (markerSpeed = 0; markerSpeed <= maxSpeed; markerSpeed += 10) {
    BOOL majorMakrer = (markerSpeed / 10) % 2 == 0;
    CGFloat speedDegrees = minPositionDegrees + (markerSpeed * speedDegreeRatio);
    CGFloat markerDegreesDelta = majorMakrer ? majorMarkerDegreesDelta : minorMarkerDegreesDelta;
    CGFloat markerInnerRadius = majorMakrer ? radius * 0.8 : radius * 0.875;
    
    CAShapeLayer *markerLayer = [CAShapeLayer layer];
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(centerPoint.x + markerInnerRadius * cos(DegreesToRadians(speedDegrees + 90)), centerPoint.y + markerInnerRadius * sin(DegreesToRadians(speedDegrees + 90)))];
    [path addLineToPoint:CGPointMake(centerPoint.x + radius * cos(DegreesToRadians(speedDegrees + 90 - markerDegreesDelta)), centerPoint.y + radius * sin(DegreesToRadians(speedDegrees + 90 - markerDegreesDelta)))];
    [path addLineToPoint:CGPointMake(centerPoint.x + radius * cos(DegreesToRadians(speedDegrees + 90 + markerDegreesDelta)), centerPoint.y + radius * sin(DegreesToRadians(speedDegrees + 90 + markerDegreesDelta)))];
    [path closePath];
    markerLayer.path = path.CGPath;
    markerLayer.fillColor = [UIColor blackColor].CGColor;
    
    [self.layer addSublayer:markerLayer];
    [speedMarkerLayers addObject:markerLayer];
    
    if (majorMakrer) {
      CGFloat labelRadius = radius - (radius / 2.5);
      labelRadius += radius * ((fabsf(0.5 - (speedDegrees / 360))) * 0.15); // move radius a bit closer to the outside depending how close to the bottom it is... looks good. trust me.
      CGFloat labelCenterX = floor((labelRadius * cos(((speedDegrees + 90) * M_PI) / 180.0f)) + centerPoint.x);
      CGFloat labelCenterY = floor((labelRadius * sin(((speedDegrees + 90) * M_PI) / 180.0f)) + centerPoint.y);
      CGFloat labelWidth = radius / 2.5;
      CGFloat labelHeight = radius / 4;
      
      CATextLayer *labelLayer = [CATextLayer layer];
      labelLayer.frame = CGRectMake(labelCenterX - (labelWidth / 2), labelCenterY - (labelHeight / 2), labelWidth, labelHeight);
      labelLayer.alignmentMode = @"center";
      labelLayer.fontSize = markerFont.pointSize;
      labelLayer.font = (__bridge CFTypeRef)markerFont;
      labelLayer.string = [NSString stringWithFormat:@"%lu", (unsigned long)markerSpeed];
      labelLayer.contentsScale = layerContentsScale;
      labelLayer.foregroundColor = [UIColor blackColor].CGColor;
      [self.layer addSublayer:labelLayer];
    }
  }
  self.speedMarkerLayers = speedMarkerLayers.copy;
  
  // current speed label
  CGFloat labelRadius = radius * 0.9;
  CGFloat labelCenterX = floor((labelRadius * cos(((90) * M_PI) / 180.0f)) + centerPoint.x);
  CGFloat labelCenterY = floor((labelRadius * sin(((90) * M_PI) / 180.0f)) + centerPoint.y);
  CGFloat labelWidth = radius / 1.2;
  CGFloat labelHeight = radius / 2.2;
  
  self.currentSpeedLabel = [CATextLayer layer];
  self.currentSpeedLabel.frame = CGRectMake(labelCenterX - (labelWidth / 2), labelCenterY - (labelHeight / 2), labelWidth, labelHeight);
  self.currentSpeedLabel.alignmentMode = @"center";
  self.currentSpeedLabel.fontSize = currentSpeedFont.pointSize;
  self.currentSpeedLabel.font = (__bridge CFTypeRef)currentSpeedFont;
  self.currentSpeedLabel.string = @"";
  self.currentSpeedLabel.opacity = 0;
  self.currentSpeedLabel.contentsScale = layerContentsScale;
  self.currentSpeedLabel.foregroundColor = [UIColor blackColor].CGColor;
  [self.layer addSublayer:self.currentSpeedLabel];
  
  // the speedometer needle. A transparent rectangle layer with an ancor point allowing a rotation transformation to be applied, with a triangle bezier path layer inside it.
  self.needleLayer = [CALayer layer];
  self.needleLayer.frame = CGRectMake(centerPoint.x - lineWidth, centerPoint.y - (radius / 2), lineWidth * 2, radius);
  self.needleLayer.anchorPoint = CGPointMake(0.5, 1.0);
  [self.needleLayer setValue:DegreesToNumber(minPositionDegrees - 180) forKeyPath:@"transform.rotation.z"];
  
  CAShapeLayer *needleShapeLayer = [CAShapeLayer layer];
  path = [UIBezierPath bezierPath];
  [path moveToPoint:CGPointMake(lineWidth, lineWidth)];
  [path addLineToPoint:CGPointMake(0, radius)];
  [path addLineToPoint:CGPointMake(lineWidth * 2, radius)];
  [path closePath];
  needleShapeLayer.path = path.CGPath;
  needleShapeLayer.fillColor = [UIColor redColor].CGColor;
  
  [self.needleLayer addSublayer:needleShapeLayer];
  
  [self.layer addSublayer:self.needleLayer];
  
  // center circle overlaying the speedometer needle, with a white stroke
  self.centerPointLayer = [CAShapeLayer layer];
  self.centerPointLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(centerPoint.x - radius / 15, centerPoint.y - radius / 15, radius / 7.5, radius / 7.5) cornerRadius:radius-inset].CGPath;
  self.centerPointLayer.fillColor = [UIColor redColor].CGColor;
  self.centerPointLayer.strokeColor = [UIColor whiteColor].CGColor;
  self.centerPointLayer.lineWidth = lineWidth * 0.6;
  [self.layer addSublayer:self.centerPointLayer];
  
  // put a red layer in *our superview* that fills it up entirely and can be faded in/out
  self.superviewOverSpeedLayer = [CALayer layer];
  self.superviewOverSpeedLayer.frame = self.superview.bounds;
  self.superviewOverSpeedLayer.backgroundColor = [UIColor redColor].CGColor;
  self.superviewOverSpeedLayer.opacity = 0;
  [self.superview.layer insertSublayer:self.superviewOverSpeedLayer atIndex:0];
  
  // monitor location updates
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationDataUpdated:) name:@"SLLocationDataUpdated" object:nil];
  
  // for debugging, start a timer moving the needle around
//  [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(debugMoveNeedleAround:) userInfo:nil repeats:YES];
}

- (void)locationDataUpdated:(NSNotification *)notif
{
  CGFloat speedMps = [notif.userInfo[@"currentSpeed"] floatValue];
  CGFloat averageSpeedMps = [notif.userInfo[@"averageSpeed"] floatValue];
  CGFloat averageChange = [notif.userInfo[@"averageChange"] floatValue];
  CGFloat timeInterval = [notif.userInfo[@"timeInterval"] floatValue];
  
  // convert to useful unit
  CGFloat speedKmh = speedMps * 3.6;
  CGFloat speedDegrees = minPositionDegrees + (speedKmh * speedDegreeRatio);
  
  // should we show avg speed?
  BOOL speedVisible = timeInterval > 9.5 && averageChange < 0.2;
  NSString *speedStr = [NSString stringWithFormat:@"%.1f", averageSpeedMps*3.6];
  
  // apply speed, 3 second linear animation because for an expected update of 1 per second, averaging out our speed changes over 3 seconds to limit the effect of innaccurate GPS readings
  [CATransaction begin];
  [CATransaction setAnimationDuration:1];
  
  [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
  
  [self.needleLayer setValue:DegreesToNumber(speedDegrees - 180) forKeyPath:@"transform.rotation.z"];
  
  [CATransaction commit];
  
  if (speedVisible) {
    [CATransaction begin];
    [CATransaction setAnimationDuration:0];
    self.currentSpeedLabel.string = speedStr;
    [CATransaction commit];
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:2];
    self.currentSpeedLabel.opacity = 1;
    [CATransaction commit];
  } else {
    [CATransaction begin];
    [CATransaction setAnimationDuration:2];
    self.currentSpeedLabel.opacity = 0;
    [CATransaction commit];
  }
  
  // apply speed limit colour changes
  [CATransaction begin];
  [CATransaction setAnimationDuration:3];
  CGFloat speedLimitDegrees = self.currentSpeedLimit == 0 ? 360 : (self.currentSpeedLimit * speedDegreeRatio) - 1;
  self.outerRingLayer.strokeEnd = speedLimitDegrees / (maxPositionDegrees - minPositionDegrees);
  self.outerRingOverSpeedLayer.strokeStart = speedLimitDegrees / (maxPositionDegrees - minPositionDegrees);
  
  NSUInteger markerSpeed = 0;
  for (CAShapeLayer *markerLayer in self.speedMarkerLayers) {
    if (markerSpeed < self.currentSpeedLimit || self.currentSpeedLimit == 0) {
      markerLayer.fillColor = [UIColor blackColor].CGColor;
    } else {
      markerLayer.fillColor = [UIColor redColor].CGColor;
    }
    
    markerSpeed += 10;
  }
  
  if (speedKmh > self.currentSpeedLimit && self.currentSpeedLimit != 0) {
    if (!self.overSpeedLimit) {
      self.overSpeedLimit = YES;
      self.superviewOverSpeedLayer.opacity = 1;
    }
  } else {
    if (self.overSpeedLimit) {
      self.overSpeedLimit = NO;
      self.superviewOverSpeedLayer.opacity = 0;
    }
  }
  
  [CATransaction commit];
}

@end
