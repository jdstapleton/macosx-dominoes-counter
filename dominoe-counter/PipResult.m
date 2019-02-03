//
//  PipResult.m
//  testopencv
//
//  Created by James Stapleton on 2019/1/29.
//  Copyright © 2019 James Stapleton. All rights reserved.
//

#import "PipResult.h"

@implementation PipResult
- (instancetype)initWithCenterX:(NSInteger)centerX centerY:(NSInteger)centerY radius:(NSInteger)radius {
    self = [super init];
    if (self) {
        _centerX = centerX;
        _centerY = centerY;
        _radius = radius;
    }

    return self;
}

+ (instancetype) resultWithCenterX:(NSInteger)centerX centerY:(NSInteger)centerY radius:(NSInteger)radius {
    return [[self alloc] initWithCenterX:centerX centerY:centerY radius:radius];
}


@end
