//
//  CMTPDFreeFloatingTestView.m
//  CMTPDemo
//
//  Created by Chris Miles on 12/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
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
