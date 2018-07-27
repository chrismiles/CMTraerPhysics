//
//  CMTPDWonderwallLikeViewController.h
//  CMTPDemo
//
//  Created by Chris Miles on 10/01/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
//
//  Based on traerAS3 example by Arnaud Icard, https://github.com/sqrtof5/traerAS3
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "EAGLView.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <UIKit/UIKit.h>

@interface CMTPDWonderwallLikeViewController : UIViewController <EAGLViewDelegate>

@property (weak,nonatomic) IBOutlet EAGLView *testView;
@property (weak,nonatomic) IBOutlet UIBarButtonItem* fpsLabel;
@property (weak,nonatomic) IBOutlet UILabel* fullFrameRateLabel;
@property (weak, nonatomic) IBOutlet UISwitch *fullFrameRateSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *highlightSwitch;

-(IBAction)fullFrameRateAction:(id)sender;
-(IBAction)highlightToggleAction:(id)sender;

@end

