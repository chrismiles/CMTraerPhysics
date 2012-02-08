//
//  CMTPDAttractionTestView.m
//  CMTPDemo
//
//  Created by Chris Miles on 4/12/11.
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

#import "CMTPDAttractionTestView.h"
#import "CMTPDAttractionTestLayer.h"

@implementation CMTPDAttractionTestView

+ (Class)layerClass
{
    return [CMTPDAttractionTestLayer class];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
	[self.layer setContentsScale:[UIScreen mainScreen].scale];
    }
    return self;
}

- (void)startAnimation
{
    [(CMTPDAttractionTestLayer *)self.layer startAnimation];
}

- (void)stopAnimation
{
    [(CMTPDAttractionTestLayer *)self.layer stopAnimation];
}

- (void)setFpsLabel:(UILabel *)fpsLabel
{
    [(CMTPDAttractionTestLayer *)self.layer setFpsLabel:fpsLabel];
}

- (UILabel *)fpsLabel
{
    return [(CMTPDAttractionTestLayer *)self.layer fpsLabel];
}

#pragma mark - Handle touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint position = [touch locationInView:self];
    [(CMTPDAttractionTestLayer *)self.layer setUserPosition:position];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint position = [touch locationInView:self];
    [(CMTPDAttractionTestLayer *)self.layer setUserPosition:position];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [(CMTPDAttractionTestLayer *)self.layer clearUserPosition];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [(CMTPDAttractionTestLayer *)self.layer clearUserPosition];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
