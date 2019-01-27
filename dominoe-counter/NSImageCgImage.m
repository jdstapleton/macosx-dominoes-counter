//
// Created by James Stapleton on 2019-01-27.
// Copyright (c) 2019 James Stapleton. All rights reserved.
//

#import "NSImageCgImage.h"
#if TARGET_OS_IPHONE

#else
@implementation NSImage(NSImagePlusiOSAdditions)
+ (id)imageWithCGImage:(CGImageRef)pCGImage {
    NSSize mySize = { CGImageGetWidth(pCGImage), CGImageGetHeight(pCGImage) };

    return [[NSImage alloc] initWithCGImage:pCGImage size:mySize];
}

- (CGImageRef)CGImage {
    NSSize rectSize = [self size];
    CGRect rect = CGRectMake(0, 0, rectSize.width, rectSize.height);
    return [self CGImageForProposedRect:&rect context:nil hints:nil];
}

@end
#endif