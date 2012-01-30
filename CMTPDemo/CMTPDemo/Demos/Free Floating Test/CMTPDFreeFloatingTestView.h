//
//  CMTPDFreeFloatingTestView.h
//  CMTPDemo
//
//  Created by Chris Miles on 12/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CMTPDFreeFloatingTestView : UIView

@property (nonatomic, retain)   UILabel *fpsLabel;

- (void)startAnimation;
- (void)stopAnimation;

- (NSUInteger)particleCount;

@end
