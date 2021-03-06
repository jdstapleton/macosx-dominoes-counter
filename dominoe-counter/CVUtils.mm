//
// Created by James Stapleton on 2019-01-27.
// Copyright (c) 2019 James Stapleton. All rights reserved.
//

#import "CVUtils.h"

@implementation CVUtils {

}

// sign-conversion cols, rows the cv and CGBitmap disagree on type, so ignore warning
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wsign-conversion"
+ (cv::Mat)cvMatFromCGImage:(CGImageRef)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
    
    int cols = (int) CGImageGetWidth(image);   // int is what cvMat expects not float
    int rows = (int) CGImageGetHeight(image);  // int is what cvMat expects not float

    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)

    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
            cols,                       // Width of bitmap
            rows,                       // Height of bitmap
            8,                          // Bits per component
            cvMat.step[0],              // Bytes per row
            colorSpace,                 // Colorspace
            kCGImageAlphaNoneSkipLast |
                    kCGBitmapByteOrderDefault); // Bitmap info flags

    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image);
    CGContextRelease(contextRef);

    return cvMat;
}
#pragma clang diagnostic pop

+ (cv::Mat)cvMatGrayFromCGImage:(CGImageRef)image {
    cv::Mat cvMat = [CVUtils cvMatFromCGImage:image];

    // to calculate circles we need to convert to greyscale
    cv::cvtColor(cvMat, cvMat, cv::COLOR_RGB2GRAY);

    return cvMat;
}

+ (CGImageRef)generateCGImageForMat:(const cv::Mat &)mat {
    NSData *data = [NSData dataWithBytes:mat.data length:mat.elemSize()*mat.total()];
    CGColorSpaceRef colorSpace;

    if (mat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(mat.cols,                                  //width
            mat.rows,                                  //height
            8,                                          //bits per component
            8 * mat.elemSize(),                        //bits per pixel
            mat.step[0],                               //bytesPerRow
            colorSpace,                                 //colorspace
            kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
            provider,                                   //CGDataProviderRef
            NULL,                                       //decode
            false,                                      //should interpolate
            kCGRenderingIntentDefault                   //intent
    );
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return imageRef;
}

@end
