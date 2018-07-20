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

CMTPFloat randomClamp(void);

@interface CMTPDScrollViewCloneViewController ()

@end

@implementation CMTPDScrollViewCloneViewController
@synthesize contentView;
@synthesize scrollView;

-(id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)configureContentViewWithHeight:(CGFloat)height {
    CGRect frame=self.contentView.frame;
    frame.size.height=height;
    self.contentView.frame=frame;

    [self.scrollView addSubview:self.contentView];
    self.scrollView.contentSize=self.contentView.bounds.size;
    // Remove any existing distance labels
    for (UIView* subview in self.contentView.subviews) {
        if (kViewTagDistanceLabel==subview.tag) {
            [subview removeFromSuperview];
        }
    }
    // Add distance labels
    NSInteger numDistanceLabels=(NSInteger)(CGRectGetHeight(self.contentView.bounds)/kDistanceLabelOffset)-1;
    CGFloat y=kDistanceLabelOffset;
    for (NSInteger i=0;i<numDistanceLabels;i++) {
        NSString* text=[[NSString alloc] initWithFormat:@"%0.0f points",y];
        UILabel* distanceLabel=[[UILabel alloc] initWithFrame:CGRectMake(0.0f,y,0.0f,0.0f)];
        distanceLabel.text=text;
        distanceLabel.autoresizingMask=UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;

        [distanceLabel sizeToFit];

        CGRect dFrame=distanceLabel.frame;
        dFrame.origin.x=randomClamp()*(CGRectGetWidth(self.contentView.bounds)-CGRectGetWidth(dFrame));
        distanceLabel.frame=dFrame;

        [self.contentView addSubview:distanceLabel];

        y+=kDistanceLabelOffset;
    }
}

-(void)viewDidLoad {
    [super viewDidLoad];

    self.title=@"Scroll View Clone";

    UIBarButtonItem* configureItem=[[UIBarButtonItem alloc] initWithTitle:@"Configure" style:UIBarButtonItemStylePlain target:self action:@selector(configureAction:)];
    self.toolbarItems=[NSArray arrayWithObjects:configureItem,nil];

    [self configureContentViewWithHeight:5150.0f];
}

#if false
-(void)viewDidUnload {
    [self setScrollView:nil];
    [self setContentView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
#endif

-(void)configureAction:(id)sender {
    __weak CMTPDScrollViewCloneViewController* weakSelf=self;
    CMTPDScrollViewCloneConfigureViewController* viewController=[[CMTPDScrollViewCloneConfigureViewController alloc] initWithNibName:nil bundle:nil scrolldrag:self.scrollView.scrollDrag springFixedConstant:self.scrollView.fixedSpringConstant springTouchConstant:self.scrollView.touchSpringConstant];
    __weak CMTPDScrollViewCloneConfigureViewController* weakViewController=viewController;
    [weakViewController setOnFinishedHandler:^{
         CMTPDScrollViewCloneViewController* strongSelf=weakSelf;
         CMTPDScrollViewCloneConfigureViewController* strongViewController=weakViewController;
         if (strongSelf!=nil) {
             if (strongViewController!=nil) {
                 strongSelf.scrollView.scrollDrag=strongViewController.dragSlider.value;
                 strongSelf.scrollView.fixedSpringConstant=strongViewController.springFixedSlider.value;
                 strongSelf.scrollView.touchSpringConstant=strongViewController.springTouchSlider.value;
             }
             [strongSelf dismissViewControllerAnimated:YES completion:nil];
         }
     }];

    UINavigationController* navController=[[UINavigationController alloc] initWithRootViewController:weakViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

@end

/* Return a random CMTPFloat between 0.0 and 1.0 */
CMTPFloat randomClamp(){
    return (CMTPFloat)(arc4random()%((unsigned)RAND_MAX+1))/(CMTPFloat)((unsigned)RAND_MAX+1);
}

