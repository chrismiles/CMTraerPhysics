//
//  CMTPDSpringTestViewController.h
//  CMTPDemo
//
//  Created by Chris Miles on 15/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CMTPDSpringTestViewController : UIViewController

@property (retain, nonatomic) IBOutlet UIView *accelerometerToggleView;
@property (retain, nonatomic) IBOutlet UIView *smoothToggleView;
@property (retain, nonatomic) IBOutlet UILabel *fpsLabel;

- (IBAction)accelerometerToggleAction:(id)sender;
- (IBAction)smoothToggleAction:(id)sender;

@end
