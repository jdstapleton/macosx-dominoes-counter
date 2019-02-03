//
//  DominoeResult.m
//  testopencv
//
//  Created by James Stapleton on 2019/1/29.
//  Copyright © 2019 James Stapleton. All rights reserved.
//

#import "DominoeResult.h"
#import "PipResult.h"

@implementation DominoeResult
- (instancetype)initWithPips:(NSArray<PipResult *> *)pips x:(NSInteger)x y:(NSInteger)y width:(NSInteger)width height:(NSInteger)height centerX:(NSInteger)centerX centerY:(NSInteger)centerY angle:(Float32)angle {
    self = [super init];
    if (self) {
        _pips = pips;
        _x = x;
        _y = y;
        _width = width;
        _height = height;
        _centerX = centerX;
        _centerY = centerY;
        _angle = angle;
    }

    return self;
}

+ (instancetype)resultWithPips:(NSArray<PipResult *> *)pips x:(NSInteger)x y:(NSInteger)y width:(NSInteger)width height:(NSInteger)height centerX:(NSInteger)centerX centerY:(NSInteger)centerY angle:(Float32)angle {
    return [[self alloc] initWithPips:pips x:x y:y width:width height:height centerX:centerX centerY:centerY angle:angle];
}

- (NSString*) description {
    return [NSString stringWithFormat:@"Value %lu", (unsigned long) [_pips count]];
}

@end
