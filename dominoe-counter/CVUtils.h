//
// Created by James Stapleton on 2019-01-27.
// Copyright (c) 2019 James Stapleton. All rights reserved.
//
#pragma GCC diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#import <opencv2/opencv.hpp>
#include <opencv2/objdetect.hpp>
#pragma clang diagnostic pop

#import <Foundation/Foundation.h>
#include "JDSImage.h"

@interface CVUtils : NSObject
+ (cv::Mat) cvMatFromCGImage: (CGImageRef)image;
+ (cv::Mat) cvMatGrayFromCGImage: (CGImageRef)image;
+ (CGImageRef) generateCGImageForMat:(const cv::Mat &)mat;
@end
