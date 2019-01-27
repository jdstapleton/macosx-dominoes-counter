//
//  DominoeDectorSettings.m
//  testopencv
//
//  Created by James Stapleton on 2019/1/26.
//  Copyright © 2019 James Stapleton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DominoeDectorSettings.h"

@implementation DominoeDectorSettings
- (id) init {
    if ( self = [super init] ) {
        _lowerAreaThreshold = 3200;
        _upperAreaThreshold = 30000;
        _bwThreshold = 125;
        _bwOnValue = 255;
        _cannyLowThreshold = 3;
        _cannyRatio = 3;
        _cannyKernelSize = 3;
        _minRadius = 12;
    }

    return self;
}
@end
