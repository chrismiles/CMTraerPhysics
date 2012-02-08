//
//  CMTPDSpringTestView.m
//  CMTPDemo
//
//  Created by Chris Miles on 15/12/11.
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

#import "CMTPDSpringTestView.h"
#import "CMTPDSpringTestLayer.h"

@implementation CMTPDSpringTestView

@dynamic fpsLabel;
@dynamic gravityByDeviceMotionEnabled;
@dynamic isDeviceMotionAvailable;
@dynamic smoothed;

+ (Class)layerClass
{
    return [CMTPDSpringTestLayer class];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
	[self.layer setContentsScale:[UIScreen mainScreen].scale];
    }
    return self;
}

- (void)startAnimation
{
    [(CMTPDSpringTestLayer *)self.layer startAnimation];
}

- (void)stopAnimation
{
    [(CMTPDSpringTestLayer *)self.layer stopAnimation];
}

- (void)setFpsLabel:(UILabel *)fpsLabel
{
    [(CMTPDSpringTestLayer *)self.layer setFpsLabel:fpsLabel];
}

- (UILabel *)fpsLabel
{
    return [(CMTPDSpringTestLayer *)self.layer fpsLabel];
}


#pragma mark - Custom property accessors

- (BOOL)smoothed
{
    return [(CMTPDSpringTestLayer *)self.layer smoothed];
}

- (void)setSmoothed:(BOOL)smoothed
{
    [(CMTPDSpringTestLayer *)self.layer setSmoothed:smoothed];
}

- (BOOL)isDeviceMotionAvailable
{
    return [(CMTPDSpringTestLayer *)self.layer isDeviceMotionAvailable];
}

- (void)setGravityByDeviceMotionEnabled:(BOOL)gravityByDeviceMotionEnabled
{
    [(CMTPDSpringTestLayer *)self.layer setGravityByDeviceMotionEnabled:gravityByDeviceMotionEnabled];
}

- (BOOL)gravityByDeviceMotionEnabled
{
    return [(CMTPDSpringTestLayer *)self.layer gravityByDeviceMotionEnabled];
}


#pragma mark - Handle touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint position = [touch locationInView:self];
    [(CMTPDSpringTestLayer *)self.layer touchBeganAtLocation:position];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint position = [touch locationInView:self];
    [(CMTPDSpringTestLayer *)self.layer touchMovedAtLocation:position];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint position = [touch locationInView:self];
    [(CMTPDSpringTestLayer *)self.layer touchEndedAtLocation:position];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint position = [touch locationInView:self];
    [(CMTPDSpringTestLayer *)self.layer touchCancelledAtLocation:position];
}

@end
