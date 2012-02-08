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

#import "CMTPDSpringTestViewController.h"
#import "CMTPDSpringTestView.h"


@implementation CMTPDSpringTestViewController

@synthesize accelerometerToggleView;
@synthesize fpsLabel;
@synthesize smoothToggleView;


#pragma mark - UIControl actions

- (IBAction)accelerometerToggleAction:(id)sender
{
    UISwitch *aSwitch = (UISwitch *)sender;
    [(CMTPDSpringTestView *)self.view setGravityByDeviceMotionEnabled:aSwitch.on];
}

- (IBAction)smoothToggleAction:(id)sender
{
    UISwitch *aSwitch = (UISwitch *)sender;
    [(CMTPDSpringTestView *)self.view setSmoothed:aSwitch.on];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Spring Test";
    
    NSMutableArray *toolbarItems = [NSMutableArray array];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithCustomView:self.smoothToggleView] autorelease]];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithCustomView:self.fpsLabel] autorelease]];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    if ([(CMTPDSpringTestView *)self.view isDeviceMotionAvailable]) {
	[toolbarItems addObject:[[[UIBarButtonItem alloc] initWithCustomView:self.accelerometerToggleView] autorelease]];
    }
    
    self.toolbarItems = toolbarItems;
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    //    self.freeFloatingTestView.fpsLabel = self.fpsLabel;
    [(CMTPDSpringTestView *)self.view setFpsLabel:self.fpsLabel];
}

- (void)viewDidUnload
{
    [self setAccelerometerToggleView:nil];
    [self setFpsLabel:nil];
    [self setSmoothToggleView:nil];
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [(CMTPDSpringTestView *)self.view startAnimation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [(CMTPDSpringTestView *)self.view stopAnimation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - Object lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
	
    }
    return self;
}

- (void)dealloc
{
    [accelerometerToggleView release];
    [fpsLabel release];
    [smoothToggleView release];
    
    [super dealloc];
}

@end
