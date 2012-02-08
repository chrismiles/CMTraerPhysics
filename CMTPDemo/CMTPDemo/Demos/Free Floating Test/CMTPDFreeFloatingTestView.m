//
//  CMTPDFreeFloatingTestView.m
//  CMTPDemo
//
//  Created by Chris Miles on 12/12/11.
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

#import "CMTPDFreeFloatingTestView.h"
#import "CMTPDFreeFloatingTestLayer.h"

@implementation CMTPDFreeFloatingTestView

+ (Class)layerClass
{
    return [CMTPDFreeFloatingTestLayer class];
}

- (void)startAnimation
{
    [(CMTPDFreeFloatingTestLayer *)self.layer startAnimation];
}

- (void)stopAnimation
{
    [(CMTPDFreeFloatingTestLayer *)self.layer stopAnimation];
}

- (void)setFpsLabel:(UILabel *)fpsLabel
{
    [(CMTPDFreeFloatingTestLayer *)self.layer setFpsLabel:fpsLabel];
}

- (UILabel *)fpsLabel
{
    return [(CMTPDFreeFloatingTestLayer *)self.layer fpsLabel];
}

- (NSUInteger)particleCount
{
    return [(CMTPDFreeFloatingTestLayer *)self.layer particleCount];
}


#pragma mark - Handle touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint position = [touch locationInView:self];
    [(CMTPDFreeFloatingTestLayer *)self.layer setUserPosition:position];
    [(CMTPDFreeFloatingTestLayer *)self.layer clearPrevPosition];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint position = [touch locationInView:self];
    [(CMTPDFreeFloatingTestLayer *)self.layer setUserPosition:position];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [(CMTPDFreeFloatingTestLayer *)self.layer clearPrevPosition];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [(CMTPDFreeFloatingTestLayer *)self.layer clearPrevPosition];
}

@end
