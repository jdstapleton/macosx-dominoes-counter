//
// Created by James Stapleton on 2019-01-27.
// Copyright (c) 2019 James Stapleton. All rights reserved.
//

#import "PipDetector.h"
#import "CVUtils.h"
#import "DominoeResult.h"
#import "PipResult.h"

typedef std::vector<std::vector<cv::Point> > Contours;

struct JPip {
    cv::Point2f center;
    float radius;
};

struct LocalPipDetectionResult {
    std::vector<JPip> pips;
    std::vector<cv::RotatedRect> dominoes;
    std::vector<DominoeResult *> results;
    cv::Mat contourMat;
};

@interface PipDetector () {
}

- (void) annotateMat: (cv::Mat&) mat;
- (CGImageRef) generateModifiedImage;
- (CGImageRef) generateContourImage;

- (cv::Mat)matToDetect;

- (LocalPipDetectionResult)detect;

- (void)findPips:(Contours)contours withHierarchy:(std::vector<cv::Vec4i> const &)hierarchy into: (LocalPipDetectionResult&) result;
- (void)findPips:(Contours const &)contours forDomid: (int) domId withHierarchy:(const std::vector<cv::Vec4i> &)hierarchy within:(const cv::Vec4i &)within into: (std::vector<JPip>&) result;

@property(readonly) cv::Mat contourMat;
@property(readonly) LocalPipDetectionResult detection;
@property(readonly) DominoeDectorSettings* s;
@property cv::RNG rng;
@property cv::Scalar color;
@property(readonly) bool shouldCleanup;
@end

@implementation PipDetector {

}
- (id) initWithCgImage:(CGImageRef)cgImageRef {
    DominoeDectorSettings *settings = [[DominoeDectorSettings alloc] init];
    settings.minRadius = 22; // 25
    settings.maxRadius = 70; // 70
    settings.lowerAreaThreshold += 30000;
    settings.upperAreaThreshold += 100000;
    settings.bwThreshold = 190;
    
    return [self initWithCgImage:cgImageRef andSettings:settings];
}

- (id) initWithCgImage:(CGImageRef)cgImageRef andSettings:(DominoeDectorSettings *)settings {
    if (self = [super init]) {
        _originalImage = CGImageRetain(cgImageRef);
        _rng = cv::RNG(23456);
        _color = cv::Scalar(256, 0, 0);
        _s = settings;
        _detection = [self detect];
        _contourImage = [self generateContourImage];
        _modifiedImage = [self generateModifiedImage];
        _dominoes = [NSArray arrayWithObjects:&_detection.results[0] count:_detection.results.size()];
    }

    return self;
}

- (void) dealloc {
    if (_originalImage) {
        CGImageRelease(_originalImage);
    }
    
    if (_contourImage) {
        CGImageRelease(_contourImage);
    }
    
    if (_modifiedImage) {
        CGImageRelease(_modifiedImage);
    }
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

- (CGImageRef) generateModifiedImage {
    cv::Mat mat = [CVUtils cvMatGrayFromCGImage:_originalImage];
    [self annotateMat:mat];

    return [CVUtils generateCGImageForMat:mat];
}

- (CGImageRef) generateContourImage {
    cv::Mat mat = _detection.contourMat.clone();
    [self annotateMat:mat];

    return [CVUtils generateCGImageForMat:mat];
}

- (cv::Mat)matToDetect {
    cv::Mat mat = [CVUtils cvMatGrayFromCGImage:_originalImage];

    // Store the found contour points here
    Contours contours;
    std::vector<cv::Vec4i> hierarchy;
    bool doCleanup = self.shouldCleanup;

    if (doCleanup) {
        cv::GaussianBlur(mat, mat, cv::Size(3, 3), 1, 1);
        // gradient: Get a more resistant to noise operator that joints Gaussian smoothing plus differentiation operation
        //cv::Sobel(mat, mat, CV_8U, 1, 0, 3);  // gradient:
    }

    // Binary image it
    cv::threshold(mat, mat, _s.bwThreshold, _s.bwOnValue, cv::THRESH_BINARY);
    // cv::floodFill(mat, cv::Point(0,0), cv::Scalar(128));

    if (doCleanup) {
      cv::Mat structureElement = cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(5, 5));
      cv::morphologyEx(mat, mat, cv::MORPH_CLOSE, structureElement);
    }
    // cv::bitwise_not(mat, mat);

    return mat;
}

- (LocalPipDetectionResult)detect {
    cv::Mat mat = [self matToDetect];
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(mat, contours, hierarchy, cv::RETR_CCOMP, cv::CHAIN_APPROX_SIMPLE);

    LocalPipDetectionResult result;
    [self findPips:contours withHierarchy:(std::vector<cv::Vec4i> const &) hierarchy into: result];
    result.contourMat = mat;

    return result;
}

- (void)findPips:(Contours)contours withHierarchy:(std::vector<cv::Vec4i> const &)hierarchy into: (LocalPipDetectionResult &) result {
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

        if ((domContourArea > (_s.lowerAreaThreshold / 2)) && (domContourArea < (_s.upperAreaThreshold * 2))) {
            cv::RotatedRect mar = cv::minAreaRect(cur);
            printf("DOM: Not adding {%f, %f} area %f\n", mar.center.x, mar.center.y, domContourArea);
            // result.dominoes.push_back(mar);
        }
        if (domContourArea < _s.lowerAreaThreshold || domContourArea > _s.upperAreaThreshold) {
            // either too big of an area to consider, or too small of an area to consider
            printf("DOM: Primary contour(%d) is out of range %lf\n", i, domContourArea);
            continue;
        }

        cv::RotatedRect mar = cv::minAreaRect(cur);
        result.dominoes.push_back(mar);

        std::vector<JPip> pips;
        [self findPips:contours forDomid: domId withHierarchy:hierarchy within:hierarchyMeta into: pips];

        NSMutableArray<PipResult*> * ar = [[NSMutableArray alloc] initWithCapacity:pips.size()];
        for (JPip const & p : pips) {
            [ar addObject: [PipResult 
                    resultWithCenterX:(NSInteger)p.center.x 
                              centerY:(NSInteger)p.center.y 
                               radius:(NSInteger) p.radius]];
        }

        cv::Rect b = mar.boundingRect();
        DominoeResult * dr = [DominoeResult
                resultWithPips:ar
                x:b.x
                y:b.y
                width:(NSInteger) mar.size.width
                        height:(NSInteger) mar.size.height
                       centerX:(NSInteger) mar.center.x
                       centerY:(NSInteger) mar.center.y
                         angle:mar.angle];

        result.results.push_back(dr);
        result.pips.insert(std::end(result.pips), std::begin(pips), std::end(pips));
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
        if ((_s.minRadius == -1 or radius >= _s.minRadius) and (_s.maxRadius == -1 || radius <= _s.maxRadius)) {
            results.push_back({center, radius});
        } else {
            printf("PIP: Not adding pip with center (%f, %f) radius %f\n", center.x, center.y, radius);
        }

        currentChild = childMeta[0];
    }
}

- (bool) shouldCleanup {
    if (_s.imageCleanupSetting == icAUTO) {
        size_t cols = CGImageGetWidth(_originalImage);
        size_t rows = CGImageGetHeight(_originalImage);

        // auto clean up if resolution is >= 6MP
        return cols * rows >= 6000000;
    }

    return _s.imageCleanupSetting == icYES;
}


@end
