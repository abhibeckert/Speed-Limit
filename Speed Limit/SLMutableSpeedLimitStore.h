//
//  SLMutableSpeedLimitStore.h
//  Speed Limit
//
//  Created by Abhi Beckert on 27/03/2014.
//  Copyright (c) 2014 Abhi Beckert. All rights reserved.
//

#import "SLSpeedLimitStore.h"

@interface SLMutableSpeedLimitStore : SLSpeedLimitStore

- (void)addWay:(SLWay *)way;

- (void)writeToUrl:(NSURL *)url;

@end
