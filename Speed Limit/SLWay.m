//
//  SLWay.m
//  Speed Limit
//
//  Created by Abhi Beckert on 27/03/2014.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "SLWay.h"

@interface SLWay () {
  NSUInteger coordCount;
  CLLocationCoordinate2D *coords;
}

@property (strong) NSString *name;
@property NSUInteger speedLimit;

@end

@implementation SLWay

- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeObject:self.name];
  
  unsigned long speed = self.speedLimit;
  [coder encodeBytes:(void *)&speed length:sizeof(speed)];
  
  // encode the all nodes as their offset from minCoord
  unsigned long nodeCount = self.nodes.count;
  [coder encodeBytes:(void *)&nodeCount length:sizeof(nodeCount)];
  for (NSUInteger nodeIndex = 0; nodeIndex < coordCount; nodeIndex++) {
    CLLocationCoordinate2D coord = coords[nodeIndex];
    float lat = coord.latitude;
    float lon = coord.longitude;
    
    [coder encodeBytes:(void *)&lat length:sizeof(lat)];
    [coder encodeBytes:(void *)&lon length:sizeof(lon)];
  }
}

- (id)initWithCoder:(NSCoder *)decoder
{
  if (!(self = [super init]))
    return nil;
  
  self.name = [decoder decodeObject];
  self.speedLimit = *(unsigned long *)([decoder decodeBytesWithReturnedLength:NULL]);
  
  coordCount = *(unsigned long *)([decoder decodeBytesWithReturnedLength:NULL]);
  coords = malloc(coordCount * sizeof(CLLocationCoordinate2D));
  for (NSUInteger nodeIndex = 0; nodeIndex < coordCount; nodeIndex++) {
    float lat = *(float *)([decoder decodeBytesWithReturnedLength:NULL]);
    float lon = *(float *)([decoder decodeBytesWithReturnedLength:NULL]);
    
    coords[nodeIndex] = CLLocationCoordinate2DMake(lat, lon);
  }
  
  return self;
}

- (void)dealloc
{
  free(coords);
}

- (instancetype)initWithWayID:(NSUInteger)wayId name:(NSString *)name speedLimit:(NSUInteger)speed nodes:(NSArray *)nodes
{
  if (!(self = [super init]))
    return nil;
  
  self.name = name;
  self.speedLimit = speed;
  
  coordCount = nodes.count;
  coords = malloc(coordCount * sizeof(CLLocationCoordinate2D));
  for (NSUInteger nodeIndex = 0; nodeIndex < coordCount; nodeIndex++) {
    coords[nodeIndex] = CLLocationCoordinate2DMake([nodes[nodeIndex][0] doubleValue], [nodes[nodeIndex][1] doubleValue]);
  }
  
  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<SLWay> %@", [self dictionaryWithValuesForKeys:@[@"name", @"speedLimit", @"nodes"]]];
}

- (NSArray *)nodes
{
  NSMutableArray *nodes = @[].mutableCopy;
  for (NSUInteger nodeIndex = 0; nodeIndex < coordCount; nodeIndex++) {
    [nodes addObject:@[[NSNumber numberWithFloat:coords[nodeIndex].latitude], [NSNumber numberWithFloat:coords[nodeIndex].longitude]]];
  }
  
  return nodes.copy;
}

- (CLLocationCoordinate2D)minCoord
{
  CLLocationCoordinate2D minCoord = coords[0];
  
  for (NSUInteger nodeIndex = 1; nodeIndex < coordCount; nodeIndex++) {
    CLLocationCoordinate2D coord = coords[nodeIndex];
    
    if (coord.latitude < minCoord.latitude) {
      minCoord.latitude = coord.latitude;
    }
    if (coord.longitude < minCoord.longitude) {
      minCoord.longitude = coord.longitude;
    }
  }
  
  return minCoord;
}

- (CLLocationCoordinate2D)maxCoord
{
  CLLocationCoordinate2D maxCoord = coords[0];
  
  for (NSUInteger nodeIndex = 1; nodeIndex < coordCount; nodeIndex++) {
    CLLocationCoordinate2D coord = coords[nodeIndex];
    
    if (coord.latitude > maxCoord.latitude) {
      maxCoord.latitude = coord.latitude;
    }
    if (coord.longitude > maxCoord.longitude) {
      maxCoord.longitude = coord.longitude;
    }
  }
  
  return maxCoord;
}

- (BOOL)matchesLocation:(CLLocationCoordinate2D)location trail:(NSArray *)locations
{
  static CLLocationCoordinate2D invalidCoord = (CLLocationCoordinate2D){200, 200};
  
  if (coordCount == 1)
    return NO; // not a valid way, and will screw up our search algorithm
  
  for (NSUInteger nodeIndex = 0; nodeIndex < coordCount; nodeIndex++) {
    // load nodes
    CLLocationCoordinate2D nodeCoord = coords[nodeIndex];
    
    BOOL hasPrevNode = (nodeIndex > 0);
    CLLocationCoordinate2D prevNodeCoord = hasPrevNode ? coords[nodeIndex - 1] : invalidCoord;
    
    BOOL hasNextNode = (nodeIndex + 1 < coordCount);
    CLLocationCoordinate2D nextNodeCoord = hasNextNode ? coords[nodeIndex + 1] : invalidCoord;
    
    
    // check distance
    CLLocationDistance distanceToCurrent = distanceToCoord(nodeCoord, location);
    
    if (distanceToCurrent > 10000)
      return NO; // give up on this way
    
    if (distanceToCurrent > 100)
      continue; // move to the next node
    
    if (hasNextNode && hasPrevNode) {
      CLLocationDistance distanceToNext = distanceToCoord(nodeCoord, nextNodeCoord);
      CLLocationDistance distanceToPrev = distanceToCoord(nodeCoord, prevNodeCoord);
      if (distanceToNext < (distanceToCurrent + 5) && distanceToPrev < (distanceToCurrent + 5))
        continue;
    } else if (hasNextNode) {
      CLLocationDistance distanceToNext = distanceToCoord(nodeCoord, nextNodeCoord);
      if (distanceToNext < (distanceToCurrent + 5))
        continue;
    } else if (hasPrevNode) {
      CLLocationDistance distanceToPrev = distanceToCoord(nodeCoord, prevNodeCoord);
      if (distanceToPrev < (distanceToCurrent + 5))
        continue;
    }
    
    // check bearing
    double bearingToCurrent = bearingToCoord(nodeCoord, location);
    if (hasNextNode & hasPrevNode) {
      double bearingToNext = bearingToCoord(nodeCoord, nextNodeCoord);
      double bearingToPrev = bearingToCoord(nodeCoord, prevNodeCoord);
      double bearingDifference = MIN(fabs(bearingToCurrent - bearingToNext), fabs(bearingToCurrent - bearingToPrev));
      
      if (bearingDifference > 15)
        continue;
    } else if (hasNextNode) {
      double bearingToNext = bearingToCoord(nodeCoord, nextNodeCoord);
      double bearingDifference = fabs(bearingToCurrent - bearingToNext);
      
      if (bearingDifference > 15)
        continue;
    } else if (hasPrevNode) {
      double bearingToPrev = bearingToCoord(nodeCoord, prevNodeCoord);
      double bearingDifference = fabs(bearingToCurrent - bearingToPrev);
      
      if (bearingDifference > 15)
        continue;
    }
    
    return YES;
  }
  
  return NO;
}

- (CLLocationDistance)distanceFromLocation:(CLLocationCoordinate2D)location
{
  if (coordCount == 1)
    return NO; // not a valid way, and will screw up our search algorithm
  
  CGFloat distance = CGFLOAT_MAX;
  
  for (NSUInteger nodeIndex = 1; nodeIndex < coordCount; nodeIndex++) {
    // load nodes
    CLLocationCoordinate2D nodeCoord = coords[nodeIndex];
    
    CLLocationCoordinate2D prevNodeCoord = coords[nodeIndex - 1];
    
    
    // check distance
    CGFloat distanceToCurrent = FindDistanceToSegment(prevNodeCoord.longitude, prevNodeCoord.latitude, nodeCoord.longitude, nodeCoord.latitude, location.longitude, location.latitude);
    
    if (distanceToCurrent < distance)
      distance = distanceToCurrent;
  }
  
  return distance * 111111; // a "distance" of 1.0 is approximately 111,111 meters
}

@end
