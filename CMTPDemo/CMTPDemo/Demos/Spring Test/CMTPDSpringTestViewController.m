//
//  CMTPDSpringTestViewController.m
//  CMTPDemo
//
//  Created by Chris Miles on 15/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
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
