//
//  CMTPDClothTestViewController.h
//  CMTPDemo
//
//  Created by Chris Miles on 6/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "EAGLView.h"

@interface CMTPDClothTestViewController : UIViewController <EAGLViewDelegate>

@property (retain, nonatomic) IBOutlet UIView *accelerometerToggleView;
@property (retain, nonatomic) IBOutlet UILabel *fpsLabel;
@property (retain, nonatomic) IBOutlet UILabel *fullFrameRateLabel;
@property (retain, nonatomic) IBOutlet UIView *gridToggleView;
@property (retain, nonatomic) IBOutlet UIView *imageToggleView;

- (IBAction)accelerometerToggleAction:(id)sender;
- (IBAction)gridToggleAction:(id)sender;
- (IBAction)imageToggleAction:(id)sender;

@end
