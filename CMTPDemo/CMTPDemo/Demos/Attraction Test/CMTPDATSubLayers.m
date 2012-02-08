//
//  CMTPDATSubLayers.m
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

#import "CMTPDATSubLayers.h"


#pragma mark - CMTPDATTouchIndicatorLayer

@implementation CMTPDATTouchIndicatorLayer

- (void)drawInContext:(CGContextRef)ctx
{
    CGRect bounds = CGContextGetClipBoundingBox(ctx);
    CGContextSetStrokeColorWithColor(ctx, [UIColor grayColor].CGColor);
    CGContextAddEllipseInRect(ctx, CGRectInset(bounds, 2.0f, 2.0f));
    CGContextDrawPath(ctx, kCGPathStroke);
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


#pragma mark - CMTPDATAnchorLayer

@implementation CMTPDATAnchorLayer

- (void)drawInContext:(CGContextRef)ctx
{
    CGRect bounds = CGContextGetClipBoundingBox(ctx);
    CGContextSetStrokeColorWithColor(ctx, [UIColor grayColor].CGColor);
    CGContextAddRect(ctx, CGRectInset(bounds, 2.0f, 2.0f));
    CGContextDrawPath(ctx, kCGPathStroke);
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


#pragma mark - CMTPDATParticleLayer

@implementation CMTPDATParticleLayer

- (void)drawInContext:(CGContextRef)ctx
{
    CGRect bounds = CGRectInset(CGContextGetClipBoundingBox(ctx), 2.0f, 2.0f);
    
    CGContextAddEllipseInRect(ctx, bounds);
    CGContextSetFillColorWithColor(ctx, [UIColor blueColor].CGColor);
    
    CGContextDrawPath(ctx, kCGPathFill);
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
