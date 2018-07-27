//
//  CMTPDScrollViewCloneViewController.m
//  CMTPDemo
//
//  Created by Chris Miles on 5/03/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
//

#import "CMTPDScrollViewCloneConfigureViewController.h"
#import "CMTPDScrollViewCloneViewController.h"

#define kViewTagDistanceLabel 101
#define kDistanceLabelOffset 100.0f

#pragma mark - C Functions
/* Return a random CMTPFloat between 0.0 and 1.0 */
CMTPFloat randomClamp(){
    return (CMTPFloat)(arc4random()%((unsigned)RAND_MAX+1))/(CMTPFloat)((unsigned)RAND_MAX+1);
}

#pragma mark - CMTPDScrollViewCloneViewController
@implementation CMTPDScrollViewCloneViewController

-(void)configureContentViewWithHeight:(CGFloat)height {
    CGRect frame=_contentView.frame;
    frame.size.height=height;
    _contentView.frame=frame;
    [_scrollView addSubview:_contentView];
    _scrollView.contentSize=_contentView.bounds.size;
    // Remove any existing distance labels
    for (UIView* subview in _contentView.subviews) {
        if (kViewTagDistanceLabel==subview.tag) {
            [subview removeFromSuperview];
        }
    }
    // Add distance labels
    NSInteger numDistanceLabels=(NSInteger)(CGRectGetHeight(_contentView.bounds)/kDistanceLabelOffset)-1;
    CGFloat y=kDistanceLabelOffset;
    for (NSInteger i=0;i<numDistanceLabels;i++) {
        NSString* text=[[NSString alloc] initWithFormat:@"%0.0f points",y];
        UILabel* distanceLabel=[[UILabel alloc] initWithFrame:CGRectMake(0.0f,y,0.0f,0.0f)];
        distanceLabel.text=text;
        distanceLabel.autoresizingMask=UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        [distanceLabel sizeToFit];
        CGRect dFrame=distanceLabel.frame;
        dFrame.origin.x=randomClamp()*(CGRectGetWidth(_contentView.bounds)-CGRectGetWidth(dFrame));
        distanceLabel.frame=dFrame;
        [_contentView addSubview:distanceLabel];
        y+=kDistanceLabelOffset;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"configureSegue"]) {
        CMTPDScrollViewCloneConfigureViewController *controller = (CMTPDScrollViewCloneConfigureViewController *)[segue destinationViewController];
        [controller setScrollView:_scrollView];
    }
}

-(void)viewDidLoad {
    [super viewDidLoad];
    [self configureContentViewWithHeight:5150.0f];
}

@end

