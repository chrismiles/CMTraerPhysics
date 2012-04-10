//
//  CMTPDScrollViewCloneConfigureViewController.m
//  CMTPDemo
//
//  Created by Chris Miles on 7/03/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
//

#import "CMTPDScrollViewCloneConfigureViewController.h"

@interface CMTPDScrollViewCloneConfigureViewController () {
    float _scrollDrag;
    BOOL _springEqual;
    float _springFixedConstant;
    float _springTouchConstant;
}

@end

@implementation CMTPDScrollViewCloneConfigureViewController

@synthesize dragSlider = _dragSlider;
@synthesize springEqualSwitch = _springEqualSwitch;
@synthesize springFixedSlider = _springFixedSlider;
@synthesize springTouchSlider = _springTouchSlider;

@synthesize onFinishedHandler = _onFinishedHandler;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil scrolldrag:(float)scrollDrag springFixedConstant:(float)springFixedConstant springTouchConstant:(float)springTouchConstant
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
	_scrollDrag = scrollDrag;
	_springFixedConstant = springFixedConstant;
	_springTouchConstant = springTouchConstant;
	
	if (_springFixedConstant == _springTouchConstant) {
	    _springEqual = YES;
	}
	else {
	    _springEqual = NO;
	}
    }
    return self;
}

- (void)dealloc
{
    [_onFinishedHandler release];
    
    [_dragSlider release];
    [_springEqualSwitch release];
    [_springFixedSlider release];
    [_springTouchSlider release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Configure Scroll View";
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)] autorelease];
    
    self.dragSlider.value = _scrollDrag;
    self.springFixedSlider.value = _springFixedConstant;
    self.springTouchSlider.value = _springTouchConstant;
    self.springEqualSwitch.on = _springEqual;
}

- (void)viewDidUnload
{
    [self setDragSlider:nil];
    [self setSpringEqualSwitch:nil];
    [self setSpringFixedSlider:nil];
    [self setSpringTouchSlider:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)doneAction:(id)sender
{
    if (self.onFinishedHandler) {
	self.onFinishedHandler();
    }
}

- (IBAction)springEqualValueChanged:(id)sender
{
    _springEqual = self.springEqualSwitch.on;
}

- (IBAction)springFixedValueChanged:(id)sender
{
    if (_springEqual && self.springTouchSlider.value != self.springFixedSlider.value) {
	self.springTouchSlider.value = self.springFixedSlider.value;
    }
}

- (IBAction)springTouchValueChanged:(id)sender
{
    if (_springEqual && self.springTouchSlider.value != self.springFixedSlider.value) {
	self.springFixedSlider.value = self.springTouchSlider.value;
    }
}

@end
