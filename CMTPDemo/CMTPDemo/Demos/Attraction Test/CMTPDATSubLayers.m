//
//  CMTPDATSubLayers.m
//  CMTPDemo
//
//  Created by Chris Miles on 4/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
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
