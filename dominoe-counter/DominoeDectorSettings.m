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
        _imageCleanupSetting = icAUTO;
        _lowerAreaThreshold =  99999;
        _upperAreaThreshold = 200000;
        _bwThreshold = 188;
        _bwOnValue = 255;
        _cannyLowThreshold = 3;
        _cannyRatio = 3;
        _cannyKernelSize = 3;
        _minRadius = 12;
        _maxRadius = 30;
    }

    return self;
}
@end
