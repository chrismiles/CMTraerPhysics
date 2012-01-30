//
//  CMTPDSpringTestLayer.h
//  CMTPDemo
//
//  Created by Chris Miles on 15/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CMTPDSpringTestLayer : CALayer

@property (nonatomic, retain) UILabel *fpsLabel;
@property (nonatomic, assign) BOOL gravityByDeviceMotionEnabled;
@property (nonatomic, assign, readonly) BOOL isDeviceMotionAvailable;
@property (nonatomic, assign) BOOL smoothed;

- (void)startAnimation;
- (void)stopAnimation;

- (void)touchBeganAtLocation:(CGPoint)location;
- (void)touchMovedAtLocation:(CGPoint)location;
- (void)touchEndedAtLocation:(CGPoint)location;
- (void)touchCancelledAtLocation:(CGPoint)location;

@end
