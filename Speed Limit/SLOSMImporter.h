//
//  SLOSMImporter.h
//  Speed Limit
//
//  Created by Abhi Beckert on 27/03/2014.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import <Foundation/Foundation.h>

#import "SLMutableSpeedLimitStore.h"
#import "SLWay.h"

@interface SLOSMImporter : NSObject

@property NSUInteger countWaysWithSpeedLimit;

- (instancetype)initWithStore:(SLMutableSpeedLimitStore *)store importURL:(NSURL *)url;

- (void)importWithCompletion:(void (^)())completionCallback progressUpdates:(void (^)(float progress))progressCallback;

@end
