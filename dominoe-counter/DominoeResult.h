//
//  DominoeResult.h
//  testopencv
//
//  Created by James Stapleton on 2019/1/29.
//  Copyright © 2019 James Stapleton. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PipResult;

NS_ASSUME_NONNULL_BEGIN

@interface DominoeResult : NSObject

@property (readonly) NSArray<PipResult*>* pips;
@property (readonly) NSInteger x;
@property (readonly) NSInteger y;
@property (readonly) NSInteger width;
@property (readonly) NSInteger height;
@property (readonly) NSInteger centerX;
@property (readonly) NSInteger centerY;
@property (readonly) Float32 angle;

- (instancetype)initWithPips:(NSArray<PipResult *> *)pips x:(NSInteger)x y:(NSInteger)y width:(NSInteger)width height:(NSInteger)height centerX:(NSInteger)centerX centerY:(NSInteger)centerY angle:(Float32)angle;

+ (instancetype)resultWithPips:(NSArray<PipResult *> *)pips x:(NSInteger)x y:(NSInteger)y width:(NSInteger)width height:(NSInteger)height centerX:(NSInteger)centerX centerY:(NSInteger)centerY angle:(Float32)angle;

@end

NS_ASSUME_NONNULL_END
