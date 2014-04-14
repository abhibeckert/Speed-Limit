//
//  NSData+SLNSDataCompression.h
//  Speed Limit
//
//  Created by Abhi Beckert on 13/04/2014.
//  Copyright (c) 2014 Abhi Beckert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (SLNSDataCompression)

// ZLIB
- (NSData *) zlibInflate;
- (NSData *) zlibDeflate;

// GZIP
- (NSData *) gzipInflate;
- (NSData *) gzipDeflate;

@end
