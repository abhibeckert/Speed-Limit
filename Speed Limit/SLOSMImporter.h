//
//  SLOSMImporter.h
//  Speed Limit
//
//  Created by Abhi Beckert on 27/03/2014.
//  Copyright (c) 2014 Abhi Beckert. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SLMutableSpeedLimitStore.h"
#import "SLWay.h"

@interface SLOSMImporter : NSObject

- (instancetype)initWithStore:(SLMutableSpeedLimitStore *)store importURL:(NSURL *)url;

- (void)import;

@end
