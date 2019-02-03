//
// Created by James Stapleton on 2019-01-27.
// Copyright (c) 2019 James Stapleton. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "DominoeDectorSettings.h"
#import "JDSImage.h"

@class DominoeResult;
NS_ASSUME_NONNULL_BEGIN

@interface PipDetector : NSObject {

}
- (id) initWithCgImage:(CGImageRef) cgImageRef;
- (id) initWithCgImage:(CGImageRef) cgImageRef andSettings: (DominoeDectorSettings*) settings;

@property(readonly) CGImageRef originalImage;
@property(readonly) CGImageRef modifiedImage;
@property(readonly) CGImageRef contourImage;
@property(readonly) NSArray<DominoeResult*>* dominoes;
@end
NS_ASSUME_NONNULL_END
