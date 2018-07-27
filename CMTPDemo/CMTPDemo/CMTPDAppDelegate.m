//
//  CMTPDAppDelegate.m
//  CMTPDemo
//
//  Created by Chris Miles on 13/11/11.
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

#import "CMTPDAppDelegate.h"

@interface CMTPDAppDelegate () <UISplitViewControllerDelegate>
@end

@implementation CMTPDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    splitViewController.delegate = self;
    return YES;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController
collapseSecondaryViewController:(UIViewController *)secondaryViewController
  ontoPrimaryViewController:(UIViewController *)primaryViewController {
    // "NO to let the split view controller try and incorporate the secondary
    // view controller’s content into the collapsed interface or YES to
    // indicate that you do not want the split view controller to do anything
    // with the secondary view controller."
    // https://developer.apple.com/documentation/uikit/uisplitviewcontrollerdelegate/1623184-splitviewcontroller?language=objc
    if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
        // iPad - Add the Info detail view at start.
        return NO;
    } else {
        // iPhone - Just show master table view at start.
        return YES;
    }
}

@end
