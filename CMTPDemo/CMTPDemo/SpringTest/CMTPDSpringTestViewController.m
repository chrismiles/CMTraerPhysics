//
//  CMTPDSpringTestViewController.m
//  CMTPDemo
//
//  Created by Chris Miles on 15/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
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

#import "CMTPDSpringTestView.h"
#import "CMTPDSpringTestViewController.h"
#import <CoreMotion/CoreMotion.h>

#pragma mark - Static Globals
// Static globals so revisiting same demo remembers control settings.
static BOOL viewedBefore;
static BOOL showSmooth;
static BOOL showAccel;

#pragma mark - CMTPDSpringTestViewController
@interface CMTPDSpringTestViewController ()
@property (strong,nonatomic) CMMotionManager* motionManager;
@end

@implementation CMTPDSpringTestViewController

#pragma mark - UIControl actions

-(IBAction)accelToggleAction:(id)sender {
    UISwitch* aSwitch=(UISwitch*)sender;
    showAccel=aSwitch.on;
    [self.testView setGravityByDeviceMotionEnabled:showAccel];
}

-(IBAction)smoothToggleAction:(id)sender {
    UISwitch* aSwitch=(UISwitch*)sender;
    showSmooth=aSwitch.on;
    [self.testView setSmoothed:showSmooth];
}

#pragma mark - View lifecycle

-(void)viewDidLoad {
    [super viewDidLoad];
    self.motionManager=[[CMMotionManager alloc] init];
    _motionManager.deviceMotionUpdateInterval=0.02;   // 50 Hz
    _accelSwitch.enabled=_motionManager.isDeviceMotionAvailable;
    if (!viewedBefore) {
        showSmooth=_smoothSwitch.on;
        showAccel=_accelSwitch.on;
        viewedBefore=YES;
    } else {
        _smoothSwitch.on=showSmooth;
        _accelSwitch.on=showAccel;
    };
    [self.navigationController setToolbarHidden:NO animated:YES];
    [self.testView setFpsLabel:_fpsLabel];
    [self.testView setSmoothed:showSmooth];
    [self.testView setGravityByDeviceMotionEnabled:showAccel];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.testView startAnimation];
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id)coordinator {
    // before rotation
    UISplitViewController *splitViewController=self.splitViewController;
    UINavigationController *navigationController=splitViewController.viewControllers[0];
    UIViewController* masterViewController=navigationController.viewControllers[0];
    [masterViewController.navigationController popToRootViewControllerAnimated:NO];
    [coordinator animateAlongsideTransition:^(id  _Nonnull context) {
        // resize our content view ...
    } completion:^(id  _Nonnull context) {
        // after rotation
        [masterViewController performSegueWithIdentifier:@"springTestSegue" sender:nil];
    }];
}

-(void)viewDidDisappear:(BOOL)animated {
    [self.testView stopAnimation];
    [super viewDidDisappear:animated];
}

@end

