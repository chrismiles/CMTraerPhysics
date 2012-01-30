//
//  CMTPDSpringTestView.h
//  CMTPDemo
//
//  Created by Chris Miles on 15/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CMTPDSpringTestView : UIView

@property (nonatomic, assign) BOOL gravityByDeviceMotionEnabled;
@property (nonatomic, assign, readonly) BOOL isDeviceMotionAvailable;
@property (nonatomic, assign) BOOL smoothed;

@property (nonatomic, retain) UILabel *fpsLabel;

- (void)startAnimation;
- (void)stopAnimation;

@end
