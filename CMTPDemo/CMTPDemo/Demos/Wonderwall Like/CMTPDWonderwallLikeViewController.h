//
//  CMTPDWonderwallLikeViewController.h
//  CMTPDemo
//
//  Created by Chris Miles on 10/01/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "EAGLView.h"

@interface CMTPDWonderwallLikeViewController : UIViewController <EAGLViewDelegate>

@property (retain, nonatomic) IBOutlet UILabel *fpsLabel;
@property (retain, nonatomic) IBOutlet UILabel *fullFrameRateLabel;
@property (retain, nonatomic) IBOutlet UIView *fullFrameRateToggleView;
@property (retain, nonatomic) IBOutlet UIView *highlightToggleView;

- (IBAction)fullFrameRateAction:(id)sender;
- (IBAction)highlightToggleAction:(id)sender;

@end
