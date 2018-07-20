//
//  CMScrollView.h
//  CMTPDemo
//
//  Created by Chris Miles on 5/03/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CMTPCommon.h"

@interface CMScrollView : UIView

@property (nonatomic) CGPoint contentOffset; // default CGPointZero
@property (nonatomic) CGSize contentSize;    // default CGSizeZero

/* Scroll physics settings.
 * Defaults result in similar behaviour to UIScrollView.
 */
@property (nonatomic) CMTPFloat fixedSpringConstant;
@property (nonatomic) CMTPFloat touchSpringConstant;
@property (nonatomic) CMTPFloat scrollDrag;

@end
