//
//  CMTPDWebTestViewController.h
//  CMTPDemo
//
//  Created by Chris Miles on 30/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "EAGLView.h"

@interface CMTPDWebTestViewController : UIViewController <EAGLViewDelegate>

@property (retain, nonatomic) IBOutlet UILabel *fpsLabel;
@property (retain, nonatomic) IBOutlet UILabel *fullFrameRateLabel;
@property (retain, nonatomic) IBOutlet UIView *fullFrameRateToggleView;
@property (retain, nonatomic) IBOutlet UIView *modifyStructureToggleView;

- (IBAction)fullFrameRateAction:(id)sender;
- (IBAction)modifyStructureAction:(id)sender;

@end
