//
//  DominoeDectorSettings.h
//  testopencv
//
//  Created by James Stapleton on 2019/1/26.
//  Copyright © 2019 James Stapleton. All rights reserved.
//

#ifndef DominoeDectorSettings_h
#define DominoeDectorSettings_h

@interface DominoeDectorSettings : NSObject {
}

@property(nonatomic) int lowerAreaThreshold;
@property(nonatomic) int upperAreaThreshold;
@property(nonatomic) int bwThreshold;
@property(nonatomic) int bwOnValue;
@property(nonatomic) int cannyLowThreshold;
@property(nonatomic) int cannyRatio;
@property(nonatomic) int cannyKernelSize;
@property(nonatomic) int minRadius;
@property(nonatomic) int maxRadius;
@end

#endif /* DominoeDectorSettings_h */
