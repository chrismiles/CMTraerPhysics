//
//  CMTPDFreeFloatingTestSubLayer.m
//  CMTPDemo
//
//  Created by Chris Miles on 12/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
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
