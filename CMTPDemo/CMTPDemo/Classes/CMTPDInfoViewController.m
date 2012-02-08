//
//  CMTPDInfoViewController.m
//  CMTPDemo
//
//  Created by Chris Miles on 6/02/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
//

#import "CMTPDInfoViewController.h"

@implementation CMTPDInfoViewController
@synthesize infoWebView;


#pragma mark - UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (UIWebViewNavigationTypeOther == navigationType) {
	return YES;
    }
    
    [[UIApplication sharedApplication] openURL:request.URL];
    return NO;
}


#pragma mark - UIControl actions

- (void)doneAction:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"CMTPDemo Info";
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)] autorelease];
    
    NSString *htmlFilePath = [[NSBundle mainBundle] pathForResource:@"info" ofType:@"html"];
    NSURL *url = [NSURL fileURLWithPath:htmlFilePath];
    NSURLRequest *fileRequest = [NSURLRequest requestWithURL:url];
    [self.infoWebView loadRequest:fileRequest];
}

- (void)viewDidUnload
{
    [self setInfoWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc
{
    [infoWebView release];
    [super dealloc];
}

@end
