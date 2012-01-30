//
//  CMTPDAttractionGridViewController.h
//  CMTPDemo
//
//  Created by Chris Miles on 14/11/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "EAGLView.h"

@interface CMTPDAttractionGridViewController : UIViewController <EAGLViewDelegate>

@property (retain, nonatomic) IBOutlet UILabel *fpsLabel;
@property (retain, nonatomic) IBOutlet UILabel *fullFrameRateLabel;
@property (retain, nonatomic) IBOutlet EAGLView *glView;
@property (retain, nonatomic) IBOutlet UIView *gridToggleView;
@property (retain, nonatomic) IBOutlet UIView *imageToggleView;

- (IBAction)gridToggleAction:(id)sender;
- (IBAction)imageToggleAction:(id)sender;

@end
