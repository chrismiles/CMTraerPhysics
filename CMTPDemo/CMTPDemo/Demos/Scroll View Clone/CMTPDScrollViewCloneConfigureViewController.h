//
//  CMTPDScrollViewCloneConfigureViewController.h
//  CMTPDemo
//
//  Created by Chris Miles on 7/03/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CMTPDScrollViewCloneConfigureViewController : UIViewController

@property (nonatomic, copy) void (^onFinishedHandler)(void);

@property (strong, nonatomic) IBOutlet UISlider *dragSlider;
@property (strong, nonatomic) IBOutlet UISwitch *springEqualSwitch;
@property (strong, nonatomic) IBOutlet UISlider *springFixedSlider;
@property (strong, nonatomic) IBOutlet UISlider *springTouchSlider;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil scrolldrag:(float)scrollDrag springFixedConstant:(float)springFixedConstant springTouchConstant:(float)springTouchConstant;

- (IBAction)springEqualValueChanged:(id)sender;
- (IBAction)springFixedValueChanged:(id)sender;
- (IBAction)springTouchValueChanged:(id)sender;

@end
