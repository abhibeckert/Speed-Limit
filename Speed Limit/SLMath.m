//
//  SLMath.c
//  Speed Limit
//
//  Created by Abhi Beckert on 30/03/2014.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "SLMath.h"

double degreesToRadians(double degrees)
{
  return degrees * M_PI / 180.0;
}

double radiansToDegrees(double radians)
{
  return radians * 180.0 / M_PI;
}

// http://stackoverflow.com/questions/639695/how-to-convert-latitude-or-longitude-to-meters
CLLocationDistance distanceToCoord(CLLocationCoordinate2D coord1, CLLocationCoordinate2D coord2)
{
  double R = 6378.137; // Radius of earth in KM
  double dLat = (coord1.latitude - coord2.latitude) * M_PI / 180;
  double dLon = (coord1.longitude - coord2.longitude) * M_PI / 180;
  double a = sin(dLat/2) * sin(dLat/2) +
  cos(coord2.latitude * M_PI / 180) * cos(coord1.latitude * M_PI / 180) *
  sin(dLon/2) * sin(dLon/2);
  double c = 2 * atan2(sqrt(a), sqrt(1-a));
  double distance = R * c;
  
  return distance * 1000; // meters
}

// http://stackoverflow.com/questions/8123049/calculate-bearing-between-two-locations-lat-long
CLLocationDirection bearingToCoord(CLLocationCoordinate2D coord1, CLLocationCoordinate2D coord2)
{
  double dLon = (coord2.longitude-coord1.longitude);
  double y = sin(dLon) * cos(coord2.latitude);
  double x = cos(coord1.latitude)*sin(coord2.latitude) - sin(coord1.latitude)*cos(coord2.latitude)*cos(dLon);
  double brng = radiansToDegrees((atan2(y, x)));
  
  return (360 - fmod((brng + 360), 360));
}

// http://www.cprogramto.com/c-program-to-find-shortest-distance-between-point-and-line-segment/
double FindDistanceToSegment(double x1, double y1, double x2, double y2, double pointX, double pointY)
{
  double diffX = x2 - x1;
  float diffY = y2 - y1;
  if ((diffX == 0) && (diffY == 0))
  {
    diffX = pointX - x1;
    diffY = pointY - y1;
    return sqrt(diffX * diffX + diffY * diffY);
  }
  
  float t = ((pointX - x1) * diffX + (pointY - y1) * diffY) / (diffX * diffX + diffY * diffY);
  
  if (t < 0)
  {
    //point is nearest to the first point i.e x1 and y1
    diffX = pointX - x1;
    diffY = pointY - y1;
  }
  else if (t > 1)
  {
    //point is nearest to the end point i.e x2 and y2
    diffX = pointX - x2;
    diffY = pointY - y2;
  }
  else
  {
    //if perpendicular line intersect the line segment.
    diffX = pointX - (x1 + t * diffX);
    diffY = pointY - (y1 + t * diffY);
  }
  
  //returning shortest distance
  return sqrt(diffX * diffX + diffY * diffY);
}