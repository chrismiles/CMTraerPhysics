//
//  CMTPDScrollViewCloneConfigureViewController.m
//  CMTPDemo
//
//  Created by Chris Miles on 7/03/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
//

#import "CMTPDScrollViewCloneConfigureViewController.h"
#import "CMScrollView.h"

@implementation CMTPDScrollViewCloneConfigureViewController

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_scrollView!=nil) {
        _dragSlider.value=(float)_scrollView.scrollDrag;
        _springFixedSlider.value=(float)_scrollView.fixedSpringConstant;
        _springTouchSlider.value=(float)_scrollView.touchSpringConstant;
        _springEqualSwitch.on=(_scrollView.fixedSpringConstant==_scrollView.touchSpringConstant);
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    if (_scrollView!=nil) {
        _scrollView.scrollDrag=_dragSlider.value;
        _scrollView.fixedSpringConstant=_springFixedSlider.value;
        _scrollView.touchSpringConstant=_springTouchSlider.value;
    }
    [super viewDidDisappear:animated];
}

- (IBAction)dragAction:(id)sender {
}

-(IBAction)springEqualValueChanged:(id)sender {
}

-(IBAction)springFixedValueChanged:(id)sender {
    _scrollView.fixedSpringConstant=_springFixedSlider.value;
    if (_springEqualSwitch.on&&_springTouchSlider.value!=_springFixedSlider.value) {
        _springTouchSlider.value=_springFixedSlider.value;
    }
}

-(IBAction)springTouchValueChanged:(id)sender {
    _scrollView.touchSpringConstant=_springTouchSlider.value;
    if (_springEqualSwitch.on&&_springTouchSlider.value!=_springFixedSlider.value) {
        _springFixedSlider.value=_springTouchSlider.value;
    }
}

- (IBAction)dismissAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

