//
//  CMTPDScrollViewCloneConfigureViewController.h
//  CMTPDemo
//
//  Created by Chris Miles on 7/03/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
//

#import "CMTPCommon.h"
#import <UIKit/UIKit.h>

@class CMScrollView;

@interface CMTPDScrollViewCloneConfigureViewController : UIViewController

@property (weak,nonatomic) CMScrollView* scrollView;

@property (weak,nonatomic) IBOutlet UISlider* dragSlider;
@property (weak,nonatomic) IBOutlet UISwitch* springEqualSwitch;
@property (weak,nonatomic) IBOutlet UISlider* springFixedSlider;
@property (weak,nonatomic) IBOutlet UISlider* springTouchSlider;

-(IBAction)dragAction:(id)sender;
-(IBAction)springEqualValueChanged:(id)sender;
-(IBAction)springFixedValueChanged:(id)sender;
-(IBAction)springTouchValueChanged:(id)sender;
- (IBAction)dismissAction:(id)sender;

@end

