//
//  PipResult.h
//  testopencv
//
//  Created by James Stapleton on 2019/1/29.
//  Copyright © 2019 James Stapleton. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PipResult : NSObject

@property (readonly) NSInteger centerX;
@property (readonly) NSInteger centerY;
@property (readonly) NSInteger radius;

- (instancetype)initWithCenterX:(NSInteger)centerX centerY:(NSInteger)centerY radius:(NSInteger)radius;

+ (instancetype)resultWithCenterX:(NSInteger)centerX centerY:(NSInteger)centerY radius:(NSInteger)radius;

@end

NS_ASSUME_NONNULL_END
