//
//  CMTPDAttractionTestView.m
//  CMTPDemo
//
//  Created by Chris Miles on 4/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
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
