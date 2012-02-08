//
//  CMTPDFreeFloatingTestSubLayer.m
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

#import "CMTPDFreeFloatingTestSubLayer.h"

@implementation CMTPDFreeFloatingTestSubLayer

- (void)drawInContext:(CGContextRef)ctx
{
    CGContextSetLineWidth(ctx, 2.0f);
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0.3f alpha:0.8f].CGColor);
    
    CGRect circleRect = CGRectInset(self.bounds, 1.0f, 1.0f);
    CGContextAddEllipseInRect(ctx, circleRect);
    CGContextStrokePath(ctx);
    
    CGFloat dxy = CGRectGetWidth(circleRect) * 0.4f;
    circleRect = CGRectInset(circleRect, dxy, dxy);
    CGContextAddEllipseInRect(ctx, circleRect);
    CGContextStrokePath(ctx);
}

- (id)init
{
    self = [super init];
    if (self) {
	self.contentsScale = [UIScreen mainScreen].scale;
	[self setNeedsDisplay];
    }
    return self;
}

@end
