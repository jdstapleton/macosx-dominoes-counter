//
// Created by James Stapleton on 2019-01-27.
// Copyright (c) 2019 James Stapleton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DominoeDectorSettings.h"
#import "JDSImage.h"
NS_ASSUME_NONNULL_BEGIN

@interface PipDetector : NSObject {

}
- (id) initWithUIImage:(JDSImage*)uiImage;
- (id) initWithUIImage:(JDSImage*)uiImage andSettings: (DominoeDectorSettings*) settings;
@property(readonly,retain) JDSImage* originalImage;
@property(readonly,retain) JDSImage* modifiedImage;
@property(readonly,retain) JDSImage* contourImage;
@property(readonly) NSUInteger circleCount;
@end
NS_ASSUME_NONNULL_END