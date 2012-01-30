//
//  CMTPDAttractionTestLayer.h
//  CMTPDemo
//
//  Created by Chris Miles on 4/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface CMTPDAttractionTestLayer : CALayer

@property (nonatomic, retain) UILabel *fpsLabel;

- (void)startAnimation;
- (void)stopAnimation;

- (void)clearUserPosition;
- (void)setUserPosition:(CGPoint)position;

@end
