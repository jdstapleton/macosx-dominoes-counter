//
// Created by James Stapleton on 2019-01-27.
// Copyright (c) 2019 James Stapleton. All rights reserved.
//

#import "PipDetector.h"
#import "CVUtils.h"

typedef std::vector<std::vector<cv::Point> > Contours;

struct JPip {
    int domId;
    cv::Point2f center;
    float radius;
};

struct PipDetectionResult {
    std::vector<JPip> pips;
    std::vector<cv::RotatedRect> dominoes;
    cv::Mat contourMat;
};

@interface PipDetector () {
}

- (void) annotateMat: (cv::Mat&) mat;
- (JDSImage *)generateModifiedImage;
- (JDSImage *)generateContourImage;

- (cv::Mat)matToDetect;

- (PipDetectionResult)detect;

- (void)findPips:(Contours)contours withHierarchy:(std::vector<cv::Vec4i> const &)hierarchy into: (PipDetectionResult&) result;
- (void)findPips:(Contours const &)contours forDomid: (int) domId withHierarchy:(const std::vector<cv::Vec4i> &)hierarchy within:(const cv::Vec4i &)within into: (std::vector<JPip>&) result;

@property(readonly) cv::Mat contourMat;
@property(readonly) PipDetectionResult detection;
@property cv::RNG rng;
@property cv::Scalar color;
@property cv::Scalar whiteRangeLo;
@property cv::Scalar whiteRangeUp;
@property int lowerAreaThreshold;
@property int upperAreaThreshold;
@property int bwThreshold;
@property int bwOnValue;
@property int minRadius;
@property int maxRadius;
@end

@implementation PipDetector {

}
- (id)initWithUIImage:(JDSImage *)uiImage {
    DominoeDectorSettings *settings = [[DominoeDectorSettings alloc] init];
    settings.minRadius = 22; // 25
    settings.maxRadius = 70; // 70
    settings.lowerAreaThreshold += 30000;
    settings.upperAreaThreshold += 100000;
    return [self initWithUIImage:uiImage andSettings:settings];
}

- (id)initWithUIImage:(JDSImage *)uiImage andSettings:(DominoeDectorSettings *)settings {
    if (self = [super init]) {
        _originalImage = uiImage;
        _lowerAreaThreshold = settings.lowerAreaThreshold;
        _upperAreaThreshold = settings.upperAreaThreshold;
        _bwThreshold = 190; // settings.bwThreshold;
        _bwOnValue = settings.bwOnValue;
        _minRadius = settings.minRadius;
        _maxRadius = settings.maxRadius;
        _rng = cv::RNG(23456);
        _color = cv::Scalar(256, 0, 0);
        _whiteRangeLo = cv::Scalar(240, 240, 240);
        _whiteRangeUp = cv::Scalar(255, 255, 255);
        _detection = [self detect];
        _contourImage = [self generateContourImage];
        _modifiedImage = [self generateModifiedImage];
        _circleCount = _detection.pips.size();
    }

    return self;
}

- (void) annotateMat: (cv::Mat&) mat {
    // this way we can have color in this to more easily see the circles found
    cv::cvtColor(mat, mat, cv::COLOR_GRAY2RGB);

    for (cv::RotatedRect cur : _detection.dominoes) {
        cv::Scalar color = _color;
        // We take the edges that OpenCV calculated for us
        cv::Point2f vertices2f[4];
        cur.points(vertices2f);
        // convert into points
        std::vector<cv::Point> vertices;

        for(int j = 0; j < 4; ++j){
            vertices.push_back(vertices2f[j]);
        }

        cv::polylines(mat, vertices, true, color, 3, cv::LINE_AA);
    }

    for (JPip cur : _detection.pips) {
        // cv::Scalar color = cv::Scalar(_rng.uniform(0, 256), _rng.uniform(0,256), _rng.uniform(0,256));
        cv::Scalar color = _color;
        int rad = (int) round(cur.radius);
        cv::circle(mat, cur.center, rad, color, 3);
    }

    cv::putText(mat,
            std::to_string(_detection.pips.size()),
            cv::Point2d(100, 100),
            cv::FONT_HERSHEY_SCRIPT_SIMPLEX,
            3,
            _color,
            3);
}

- (JDSImage *)generateModifiedImage {
    cv::Mat mat = [CVUtils cvMatGrayFromUIImage:_originalImage];
    [self annotateMat:mat];

    return [CVUtils generateUIImageForMat:mat];
}

- (JDSImage *)generateContourImage {
    cv::Mat mat = _detection.contourMat.clone();
    [self annotateMat:mat];

    return [CVUtils generateUIImageForMat:mat];
}

- (cv::Mat)matToDetect {
    cv::Mat mat = [CVUtils cvMatGrayFromUIImage:_originalImage];

    // Store the found contour points here
    Contours contours;
    std::vector<cv::Vec4i> hierarchy;

    cv::GaussianBlur(mat, mat, cv::Size(9, 9), 1, 1);

    // gradient: Get a more resistant to noise operator that joints Gaussian smoothing plus differentiation operation
    //cv::Sobel(mat, mat, CV_8U, 1, 0, 3);  // gradient:

    // Binary image it
    cv::threshold(mat, mat, _bwThreshold, _bwOnValue, cv::THRESH_BINARY);
    // cv::floodFill(mat, cv::Point(0,0), cv::Scalar(128));

    cv::Mat structureElement = cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(5, 5));
    cv::morphologyEx(mat, mat, cv::MORPH_CLOSE, structureElement);
    // cv::bitwise_not(mat, mat);

    return mat;
}

- (PipDetectionResult)detect {
    cv::Mat mat = [self matToDetect];
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(mat, contours, hierarchy, cv::RETR_CCOMP, cv::CHAIN_APPROX_SIMPLE);
    printf("Total contours: %ld\n", contours.size());

    PipDetectionResult result;
    [self findPips:contours withHierarchy:(std::vector<cv::Vec4i> const &) hierarchy into: result];
    result.contourMat = mat;

    printf("Pips found: %ld\n", result.pips.size());

    return result;
}

- (void)findPips:(Contours)contours withHierarchy:(std::vector<cv::Vec4i> const &)hierarchy into: (PipDetectionResult&) result {
    printf("Using dominoe area of %d => %d", _lowerAreaThreshold, _upperAreaThreshold);
    int domId = 0;
    for (int i = 0; i < hierarchy.size(); i++) {
        // {next, prev, first_child, parent}
        cv::Vec4i const &hierarchyMeta = hierarchy[i];
        if (hierarchyMeta[3] != -1) {
            // only loop through top level / external contours
            continue;
        }

        std::vector<cv::Point> cur = contours[i];
        double domContourArea = cv::contourArea(cur);

        if ((domContourArea > (_lowerAreaThreshold / 2)) && (domContourArea < (_upperAreaThreshold * 2))) {
            cv::RotatedRect mar = cv::minAreaRect(cur);
            result.dominoes.push_back(mar);
        }
        if (domContourArea < _lowerAreaThreshold || domContourArea > _upperAreaThreshold) {
            // either too big of an area to consider, or too small of an area to consider
            //printf("Primary contour(%d) is out of range %lf\n", i, domContourArea);
            continue;
        }
        printf("Looking for pips of dominoe %d (%d) with area %lf\n", domId, i, domContourArea);
        [self findPips:contours forDomid: domId withHierarchy:hierarchy within:hierarchyMeta into: result.pips];
        domId++;
    }
}

- (void)findPips:(Contours const &)contours forDomid: (int) domId withHierarchy:(const std::vector<cv::Vec4i> &)hierarchy within:(const cv::Vec4i &) within into: (std::vector<JPip>&) results {
    int currentChild = within[2];
    while (currentChild != -1) {
        cv::Vec4i const &childMeta = hierarchy[currentChild];
        std::vector<cv::Point> cur = contours[currentChild];

        cv::Point2f center;
        float radius;
        cv::minEnclosingCircle(cur, center, radius);
        if ((_minRadius == -1 or radius >= _minRadius) and (_maxRadius == -1 || radius <= _maxRadius)) {
            printf("\t(%d) Pip %d of radius %lf\n", domId, currentChild, radius);
            results.push_back({domId, center, radius});
        }

        currentChild = childMeta[0];
    }
}


@end