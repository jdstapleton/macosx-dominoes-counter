//
// Created by James Stapleton on 2019-01-27.
// Copyright (c) 2019 James Stapleton. All rights reserved.
//

#import "PipDetector.h"
#import "CVUtils.h"

typedef std::vector<std::vector<cv::Point> > Contours;

struct JCircle {
    cv::Point2f center;
    float radius;
};

struct DetectionResult {
    std::vector<JCircle> pips;
    cv::Mat contourMat;
};

@interface PipDetector() {
}

- (JDSImage*) generateModifiedImage;

- (cv::Mat) matToDetect;
- (DetectionResult) detect;

- (std::vector<JCircle>) findPips:(Contours) circles;

@property(readonly) cv::Mat contourMat;
@property(readonly) DetectionResult detection;
@property cv::RNG rng;
@property int bwThreshold;
@property int bwOnValue;
@property int minRadius;
@property int maxRadius;
@end

@implementation PipDetector {

}
- (id)initWithUIImage:(JDSImage *)uiImage {
    DominoeDectorSettings* settings = [[DominoeDectorSettings alloc] init];
    settings.minRadius = -1; // 25
    settings.maxRadius = 140;
    return [self initWithUIImage:uiImage andSettings: settings];
}

- (id)initWithUIImage:(JDSImage *)uiImage andSettings:(DominoeDectorSettings *)settings {
    if ( self = [super init] ) {
        _originalImage = uiImage;
        _bwThreshold = 190; // settings.bwThreshold;
        _bwOnValue = settings.bwOnValue;
        _minRadius = settings.minRadius;
        _maxRadius = settings.maxRadius;
        _rng = cv::RNG(23456);
        _detection = [self detect];
        _contourImage = [CVUtils generateUIImageForMat:_detection.contourMat];
        _modifiedImage = [self generateModifiedImage];
        _circleCount = _detection.pips.size();
    }

    return self;
}

- (JDSImage *)generateModifiedImage {
    cv::Mat mat = [CVUtils cvMatGrayFromUIImage:_originalImage];

    // this way we can have color in this to more easily see the circles found
    cv::cvtColor(mat, mat, cv::COLOR_GRAY2RGB);

    for (JCircle cur : _detection.pips) {
        // cv::Scalar color = cv::Scalar(_rng.uniform(0, 256), _rng.uniform(0,256), _rng.uniform(0,256));
        cv::Scalar color = cv::Scalar(256, 0, 0);
        int rad = (int) round(cur.radius);
        cv::circle(mat, cur.center, rad, color, -1);
    }

    return [CVUtils generateUIImageForMat:mat];
}

- (cv::Mat)matToDetect {
    cv::Mat mat = [CVUtils cvMatGrayFromUIImage:_originalImage];
    
    // Store the found contour points here
    Contours contours;
    std::vector<cv::Vec4i> hierarchy;

    cv::GaussianBlur(mat, mat, cv::Size(9,9), 1, 1);
    
    // gradient: Get a more resistant to noise operator that joints Gaussian smoothing plus differentiation operation
    //cv::Sobel(mat, mat, CV_8U, 1, 0, 3);  // gradient:

    // Binary image it
    cv::threshold(mat, mat, _bwThreshold, _bwOnValue, cv::THRESH_BINARY);
    //cv::floodFill(mat, cv::Point(0,0), cv::Scalar(255));

    cv::Mat structureElement = cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(5, 5));
    cv::morphologyEx(mat, mat, cv::MORPH_CLOSE, structureElement);
    
    return mat;
}

- (DetectionResult) detect {
    cv::Mat mat = [self matToDetect];
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(mat, contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_NONE);
    printf("Total circles: %ld\n", contours.size());

    DetectionResult result;
    result.pips = [self findPips: contours];
    result.contourMat = mat;

    printf("Pips found: %ld\n", result.pips.size());

    return result;
}

- (std::vector<JCircle>)findPips:(Contours)circles {
    std::vector<JCircle> filtered;
    for (std::vector<cv::Point> cur : circles) {
        cv::Point2f center;
        float radius;
        cv::minEnclosingCircle(cur, center, radius);
        if ((_minRadius == -1 or radius >= _minRadius) and (_maxRadius == -1 || radius <= _maxRadius)) {
            filtered.push_back({center, radius});
        }
    }

    return filtered;
}


@end