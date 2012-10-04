//
//  CMTPDScrollViewCloneViewController.m
//  CMTPDemo
//
//  Created by Chris Miles on 5/03/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
//

#import "CMTPDScrollViewCloneViewController.h"
#import "CMTPDScrollViewCloneConfigureViewController.h"

#define kViewTagDistanceLabel 101

#define kDistanceLabelOffset 100.0f

float randomClamp(void);


@interface CMTPDScrollViewCloneViewController ()

@end

@implementation CMTPDScrollViewCloneViewController
@synthesize contentView;
@synthesize scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [scrollView release];
    [contentView release];
    [super dealloc];
}

- (void)configureContentViewWithHeight:(CGFloat)height
{
    CGRect frame = self.contentView.frame;
    frame.size.height = height;
    self.contentView.frame = frame;
    
    [self.scrollView addSubview:self.contentView];
    self.scrollView.contentSize = self.contentView.bounds.size;
    
    // Remove any existing distance labels
    for (UIView *subview in self.contentView.subviews) {
	if (kViewTagDistanceLabel == subview.tag) {
	    [subview removeFromSuperview];
	}
    }
    
    // Add distance labels
    NSInteger numDistanceLabels = (NSInteger)(CGRectGetHeight(self.contentView.bounds) / kDistanceLabelOffset) - 1;
    CGFloat y = kDistanceLabelOffset;
    for (NSInteger i=0; i<numDistanceLabels; i++) {
	NSString *text = [[NSString alloc] initWithFormat:@"%0.0f points", y];
	UILabel *distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, y, 0.0f, 0.0f)];
	distanceLabel.text = text;
	distanceLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	
	[distanceLabel sizeToFit];
	
	CGRect dFrame = distanceLabel.frame;
	dFrame.origin.x = randomClamp() * (CGRectGetWidth(self.contentView.bounds) - CGRectGetWidth(dFrame));
	distanceLabel.frame = dFrame;
	
	[self.contentView addSubview:distanceLabel];
	
	[text release];
	[distanceLabel release];
	
	y += kDistanceLabelOffset;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Scroll View Clone";
    
    UIBarButtonItem *configureItem = [[[UIBarButtonItem alloc] initWithTitle:@"Configure" style:UIBarButtonItemStyleBordered target:self action:@selector(configureAction:)] autorelease];
    self.toolbarItems = [NSArray arrayWithObjects:configureItem, nil];
    
    [self configureContentViewWithHeight:5150.0f];
}

- (void)viewDidUnload
{
    [self setScrollView:nil];
    [self setContentView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)configureAction:(id)sender
{
    CMTPDScrollViewCloneConfigureViewController *viewController = [[[CMTPDScrollViewCloneConfigureViewController alloc] initWithNibName:nil bundle:nil scrolldrag:self.scrollView.scrollDrag springFixedConstant:self.scrollView.fixedSpringConstant springTouchConstant:self.scrollView.touchSpringConstant] autorelease];
    [viewController setOnFinishedHandler:^{
	self.scrollView.scrollDrag = viewController.dragSlider.value;
	self.scrollView.fixedSpringConstant = viewController.springFixedSlider.value;
	self.scrollView.touchSpringConstant = viewController.springTouchSlider.value;
	
	[self dismissModalViewControllerAnimated:YES];
    }];
    
    UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:viewController] autorelease];
    [self presentModalViewController:navController animated:YES];
    
}

@end


/* Return a random float between 0.0 and 1.0 */
float randomClamp()
{
    return (float)(arc4random() % ((unsigned)RAND_MAX + 1)) / (float)((unsigned)RAND_MAX + 1);
}

