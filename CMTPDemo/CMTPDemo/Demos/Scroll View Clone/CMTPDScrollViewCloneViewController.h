//
//  CMTPDScrollViewCloneViewController.h
//  CMTPDemo
//
//  Created by Chris Miles on 5/03/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CMScrollView.h"

@interface CMTPDScrollViewCloneViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet CMScrollView *scrollView;

@end
