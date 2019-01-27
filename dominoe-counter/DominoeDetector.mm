//
//  DominoeDetector.m
//  testopencv
//
//  Created by James Stapleton on 2019/1/26.
//  Copyright © 2019 James Stapleton. All rights reserved.
//
#import "DominoeDetector.h"
#import "CVUtils.h"
#import "NSImageCgImage.h"

struct DetectedDom {
    std::vector<cv::Point> points;
    cv::Rect rect;
    std::vector<cv::KeyPoint> firstPips;
    cv::Rect firstRect;

    std::vector<cv::KeyPoint> secondPips;
    cv::Rect secondRect;
};

struct DetectionResult {
    std::vector<DetectedDom> dominoes;
    cv::Mat contourMat;
};

@interface DominoeDetector() {

}
- (DetectionResult) detectDoms;

- (void) renderCirclesOf:(const std::vector<cv::KeyPoint>&) kps into:(cv::Mat&) mat withColor: (cv::Scalar const &) color;
- (void) renderOutlineDominoesInto:(cv::Mat&) mat;

- (JDSImage *)generateUIImage;
- (JDSImage *)generateContourImage;
- (size_t) countAllPips;
- (std::vector<cv::KeyPoint>) countPipsFrom:(cv::Mat&) mat within:(cv::Rect&) bounds;

@property cv::Mat mat;
@property(readonly) std::vector<DetectedDom> dominoes;
@property(readonly) cv::Mat contourMat;
@property cv::RNG rng;
@property int lowerAreaThreshold;
@property int upperAreaThreshold;
@property int bwThreshold;
@property int bwOnValue;
@property int cannyLowThreshold;
@property int cannyRatio;
@property int cannyKernelSize;
@property int minRadius;
@end

@implementation DominoeDetector

- (id) initWithUIImage:(JDSImage*)uiImage {
    return [self initWithUIImage:uiImage andSettings: [[DominoeDectorSettings alloc] init]];
}

- (id) initWithUIImage:(JDSImage*)uiImage andSettings: (DominoeDectorSettings*) settings
{
    if ( self = [super init] ) {
        _originalImage = uiImage;
        _mat = [CVUtils cvMatGrayFromUIImage:uiImage];
        _lowerAreaThreshold = settings.lowerAreaThreshold;
        _upperAreaThreshold = settings.upperAreaThreshold;
        _bwThreshold = settings.bwThreshold;
        _bwOnValue = settings.bwOnValue;
        _cannyLowThreshold = settings.cannyLowThreshold;
        _cannyRatio = settings.cannyRatio;
        _cannyKernelSize = settings.cannyKernelSize;
        _minRadius = settings.minRadius;
        _rng = cv::RNG(23456);
        DetectionResult detection = [self detectDoms];
        _dominoes = detection.dominoes;
        _contourMat = detection.contourMat;
        _contourImage = [self generateContourImage];
        _modifiedImage = [self generateUIImage];
        _circleCount = [self countAllPips];
    }

    return self;
}

- (DetectionResult) detectDoms {
    cv::Mat circles = _mat.clone();

    // Store the found contour points here
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;

    cv::blur(circles, circles, cv::Size(3,3));

    // Binary image it
    cv::threshold(circles, circles, _bwThreshold, _bwOnValue, cv::THRESH_BINARY_INV);

    // cv::GaussianBlur(circles, circles, cv::Size(3, 3), 2, 2);
    cv::Canny(circles, circles, _cannyLowThreshold, _cannyLowThreshold * _cannyRatio, _cannyKernelSize, false);

    cv::findContours(circles, contours, hierarchy, cv::RETR_TREE, cv::CHAIN_APPROX_SIMPLE); // , cv::Point(0, 0));

    std::vector<DetectedDom> found;
    size_t sum = 0;
    printf("Number of contours: %ld\n", contours.size());
    std::vector<double> areas;
    for(int i = 0; i < contours.size(); i++)
    {
        std::vector<cv::Point> &current = contours[i];
        double domContourArea = cv::contourArea(current);
        if (domContourArea > (_lowerAreaThreshold / 2)) {
            areas.push_back(domContourArea);
        }

        // filter to make sure we found the actual dominoes
        if(domContourArea > _lowerAreaThreshold && domContourArea < _upperAreaThreshold)
        {
            DetectedDom dom;
            dom.points = current;
            // Get rectangle of the dominoes
            dom.rect = cv::boundingRect(cv::Mat(current));

            // ***
            // Divide rect by 2 to determine top value and bottom value of dominoes
            // ***
            if(dom.rect.width > dom.rect.height) {
                dom.firstRect = cv::Rect(dom.rect.x, dom.rect.y, dom.rect.width / 2, dom.rect.height);
                dom.secondRect = cv::Rect(dom.rect.x + dom.rect.width / 2, dom.secondRect.y, dom.rect.width / 2, dom.rect.height);
            } else {
                // Dominoe is up right (value on top and bottom)
                dom.firstRect = cv::Rect(dom.rect.x, dom.rect.y, dom.rect.width, dom.rect.height / 2);
                dom.secondRect = cv::Rect(dom.rect.x, dom.rect.y + dom.rect.height / 2, dom.rect.width, dom.rect.height);
            }

            // Process part 1
            dom.firstPips = [self countPipsFrom:_mat within:dom.firstRect];
            sum += dom.firstPips.size();

            // Process part 2
            dom.secondPips = [self countPipsFrom:_mat within:dom.secondRect];
            sum += dom.secondPips.size();

            found.push_back(dom);
        }
    }

    DetectionResult result;
    result.contourMat = circles;
    result.dominoes = found;

    if (!areas.empty()) {
        std::sort(areas.begin(), areas.end());
        std::ostringstream oss;
        std::copy(areas.rbegin(), areas.rend()-1, std::ostream_iterator<double>(oss, ","));
        oss << areas.front();
        std::cout << "Areas found: " << oss.str() << std::endl;
    } else {
        printf("No areas found");
    }

    printf("Found %ld dominoes, %ld circles\n", result.dominoes.size(), sum);

    return result;
}

- (JDSImage *)generateUIImage {
    cv::Mat generated;

    // convert to color so that we can add color outlines and they will show up more
    cv::cvtColor(_mat, generated, cv::COLOR_GRAY2RGB);

    [self renderOutlineDominoesInto: generated];

    return [CVUtils generateUIImageForMat: generated];
}

- (JDSImage *)generateContourImage {
    return [CVUtils generateUIImageForMat: _contourMat];
}

- (size_t)countAllPips {
    size_t sum = 0;

    for(size_t i = 0; i < _dominoes.size(); ++i) {
        sum += _dominoes[i].firstPips.size() + _dominoes[i].secondPips.size();
    }

    return sum;
}

- (std::vector<cv::KeyPoint>)countPipsFrom:(cv::Mat &)mat within:(cv::Rect &)bounds {
    cv::Mat dom = mat(bounds);
    // search for blobs
    cv::SimpleBlobDetector::Params params;

    // filter by interia defines how elongated a shape is.
    //   params.filterByInertia = true;
    //   params.minInertiaRatio = 0.5;
    params.filterByCircularity = true;
    params.minCircularity = 0.1;
    params.filterByColor = 1;
    params.blobColor = 255;

    // will hold our keyponts
    std::vector<cv::KeyPoint> keypoints;

    // create new blob detector with our parameters
    cv::Ptr<cv::SimpleBlobDetector> blobDetector = cv::SimpleBlobDetector::create(params);

    // detect blobs
    blobDetector->detect(dom, keypoints);

    // translate the keypoints into the original mat (so that the locations match up)
    for (cv::KeyPoint& kp : keypoints) {
        kp.pt.x = kp.pt.x + bounds.x;
        kp.pt.y = kp.pt.y + bounds.y;
    }

    // return number of pips
    return keypoints;
}


- (void)renderCirclesOf:(const std::vector<cv::KeyPoint> &)kps into:(cv::Mat &)mat withColor:(cv::Scalar const &)color {
    for(size_t j = 0; j < kps.size(); ++j) {
        const cv::KeyPoint& kp = kps[j];
        const int radius = std::max((int) kp.size, _minRadius);
        printf("drawing circle %.3lf,%.3lf,%d\n", kp.pt.x, kp.pt.y, radius);
        cv::circle(mat, kp.pt, radius, color, 3, cv::LINE_AA);
    }
}

- (void)renderOutlineDominoesInto:(cv::Mat &)mat {
    for(size_t i = 0; i < _dominoes.size(); ++i) {
        const DetectedDom& dom = _dominoes[i];
        cv::Scalar color = cv::Scalar(_rng.uniform(0, 256), _rng.uniform(0,256), _rng.uniform(0,256));
        // cv::rectangle(mat, dom.rect, color, 3);
        cv::RotatedRect mar = cv::minAreaRect(dom.points);
        // We take the edges that OpenCV calculated for us
        cv::Point2f vertices2f[4];
        mar.points(vertices2f);
        // convert into points
        std::vector<cv::Point> vertices;

        for(int j = 0; j < 4; ++j){
            vertices.push_back(vertices2f[j]);
        }

        cv::polylines(mat, vertices, true, color, 3, cv::LINE_AA);
        [self renderCirclesOf: dom.firstPips into: mat withColor: color];
        [self renderCirclesOf: dom.secondPips into: mat withColor: color];
    }
}

@end