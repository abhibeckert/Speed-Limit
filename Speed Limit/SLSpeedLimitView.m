//
//  SLSpeedLimitView.m
//  Speed Limit
//
//  Created by Abhi Beckert on 25/03/2014.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "SLSpeedLimitView.h"

static CGFloat layerContentsScale;

@interface SLSpeedLimitView ()

@property (strong) CAShapeLayer *backgroundCircleLayer;
@property (strong) CAShapeLayer *outerRingLayer;
@property (strong) CAShapeLayer *innerCircleLayer;
@property (strong) NSArray *speedMarkerLayers;
@property (strong) CALayer *needleLayer;
@property (strong) CAShapeLayer *centerPointLayer;
@property (strong) CATextLayer *currentSpeedLabel;
@property (strong) CALayer *superviewOverSpeedLayer;

@end

@implementation SLSpeedLimitView

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
  
  
  // white circle background, so we're always on a white backdrop
  self.backgroundCircleLayer = [CAShapeLayer layer];
  UIBezierPath *path = [UIBezierPath bezierPath];
  [path moveToPoint:centerPoint];
  [path addArcWithCenter:centerPoint radius:radius + (lineWidth * 2) startAngle:0.0 endAngle:M_PI * 2.0 clockwise:YES];
  [path closePath];
  self.backgroundCircleLayer.path = path.CGPath;
  self.backgroundCircleLayer.fillColor = [UIColor whiteColor].CGColor;
  [self.layer addSublayer:self.backgroundCircleLayer];
  
  // red outer ring
  self.outerRingLayer = [CAShapeLayer layer];
  path = [UIBezierPath bezierPath];
  [path moveToPoint:centerPoint];
  [path addArcWithCenter:centerPoint radius:radius startAngle:0.0 endAngle:M_PI * 2.0 clockwise:YES];
  [path closePath];
  self.outerRingLayer.path = path.CGPath;
  self.outerRingLayer.fillColor = [UIColor redColor].CGColor;
  self.outerRingLayer.strokeColor = [UIColor redColor].CGColor;
  self.outerRingLayer.lineWidth = lineWidth;
  [self.layer addSublayer:self.outerRingLayer];
  
  // white inner ring
  self.innerCircleLayer = [CAShapeLayer layer];
  path = [UIBezierPath bezierPath];
  [path moveToPoint:centerPoint];
  [path addArcWithCenter:centerPoint radius:radius * 0.85 startAngle:0.0 endAngle:M_PI * 2.0 clockwise:YES];
  [path closePath];
  self.innerCircleLayer.path = path.CGPath;
  self.innerCircleLayer.fillColor = [UIColor whiteColor].CGColor;
  [self.layer addSublayer:self.innerCircleLayer];
  
  
  
  // speed limit
  CGFloat labelWidth = radius * 2.0;
  CGFloat labelHeight = radius * 1.22;
  UIFont *currentSpeedFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:ceil(radius)];
  
  self.currentSpeedLabel = [CATextLayer layer];
  self.currentSpeedLabel.frame = CGRectMake(centerPoint.x - (labelWidth / 2), centerPoint.y - (labelHeight / 2), labelWidth, labelHeight);
  self.currentSpeedLabel.alignmentMode = @"center";
  self.currentSpeedLabel.fontSize = currentSpeedFont.pointSize;
  self.currentSpeedLabel.font = (__bridge CFTypeRef)currentSpeedFont;
  self.currentSpeedLabel.string = @"−";
  self.currentSpeedLabel.contentsScale = layerContentsScale;
  self.currentSpeedLabel.foregroundColor = [UIColor blackColor].CGColor;
  [self.layer addSublayer:self.currentSpeedLabel];
}

- (void)setCurrentSpeedLimit:(NSUInteger)currentSpeedLimit
{
  _currentSpeedLimit = currentSpeedLimit;
  
  self.currentSpeedLabel.string = self.currentSpeedLimit == 0 ? @"−" : [NSString stringWithFormat:@"%lu", (unsigned long)self.currentSpeedLimit];
  
  CGFloat radius = floor(MIN(CGRectGetWidth(self.frame), CGRectGetWidth(self.frame)) / 2.0) - 2;
  if ([(NSString *)self.currentSpeedLabel.string length] >= 3) {
    self.currentSpeedLabel.font = (__bridge  CFTypeRef)[UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:ceil(radius)];
  } else {
    self.currentSpeedLabel.font = (__bridge  CFTypeRef)[UIFont fontWithName:@"AvenirNext-DemiBold" size:ceil(radius)];
  }
}

@end
