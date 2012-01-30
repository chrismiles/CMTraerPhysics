//
//  CMTPDAttractionTestViewController.h
//  CMTPDemo
//
//  Created by Chris Miles on 30/11/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CMTPDAttractionTestView.h"

@interface CMTPDAttractionTestViewController : UIViewController

@property (retain, nonatomic) IBOutlet CMTPDAttractionTestView *attractionTestView;
@property (retain, nonatomic) IBOutlet UILabel *fpsLabel;

@end
