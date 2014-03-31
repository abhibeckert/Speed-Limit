//
//  SLMutableSpeedLimitStore.h
//  Speed Limit
//
//  Created by Abhi Beckert on 27/03/2014.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "SLSpeedLimitStore.h"

@interface SLMutableSpeedLimitStore : SLSpeedLimitStore

- (void)addWay:(SLWay *)way;

- (void)writeToUrl:(NSURL *)url;

@end
