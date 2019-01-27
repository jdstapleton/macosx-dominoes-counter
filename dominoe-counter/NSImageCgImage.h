//
// Created by James Stapleton on 2019-01-27.
// Copyright (c) 2019 James Stapleton. All rights reserved.
//

#if TARGET_OS_IPHONE

#else
#import <AppKit/AppKit.h>
@interface NSImage(NSImagePlusiOSAdditions)
+ (id) imageWithCGImage:(CGImageRef)pCGImage;
@property (readonly) CGImageRef CGImage;
@end
#endif