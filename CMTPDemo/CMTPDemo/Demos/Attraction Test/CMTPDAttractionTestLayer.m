//
//  CMTPDAttractionTestLayer.m
//  CMTPDemo
//
//  Created by Chris Miles on 4/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//
//  Based on traerAS3 example by Arnaud Icard, https://github.com/sqrtof5/traerAS3
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

#import "CMTPDAttractionTestLayer.h"
#import "CMTraerPhysics.h"
#import "CMTPDATSubLayers.h"

@interface CMTPDAttractionTestLayer () {
    
    CADisplayLink *displayLink;
    CGSize lastSize;
    
    /* Sub Layers */
    CMTPDATAnchorLayer *anchorLayer;
    CMTPDATParticleLayer *particleLayer;
    CMTPDATTouchIndicatorLayer *touchIndicatorLayer;
    
    /* Physics */
    CMTPAttraction *attraction;
    CMTPParticle *anchor;
    CMTPParticle *attractor;
    CMTPParticle *particle;
    CMTPSpring *spring;
    CMTPParticleSystem *s;
    
    // FPS
    double fps_prev_time;
    NSUInteger fps_count;
}
@end


@implementation CMTPDAttractionTestLayer

@synthesize fpsLabel=_fpsLabel;

- (void)startAnimation
{
    if (nil == displayLink) {
	/* Init Timer */
	displayLink = [[CADisplayLink displayLinkWithTarget:self selector:@selector(drawFrame:)] retain];
	[displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopAnimation
{
    if (displayLink) {
	[displayLink invalidate];
	[displayLink release];
	displayLink = nil;
    }
}

- (void)setUserPosition:(CGPoint)position
{
    attractor.position = CMTPVector3DMake(position.x, position.y, 0.0f);
    [attraction turnOn];
    touchIndicatorLayer.opacity = 1.0f;
}

- (void)clearUserPosition
{
    [attraction turnOff];
    touchIndicatorLayer.opacity = 0.0f;
}

- (void)drawFrame:(CADisplayLink *)sender
{
    [s tick:1];
    [self setNeedsDisplay];     // draw "spring" line
    [self setNeedsLayout];      // position sub layers
    
    /* FPS */
    if (_fpsLabel) {
	double curr_time = CACurrentMediaTime(); 
	if (curr_time - fps_prev_time >= 0.2) {
	    double delta = (curr_time - fps_prev_time) / fps_count;
	    _fpsLabel.text = [NSString stringWithFormat:@"%0.0f fps", 1.0/delta];
	    fps_prev_time = curr_time;
	    fps_count = 1;
	}
	else {
	    fps_count++;
	}
    }
}

- (void)drawInContext:(CGContextRef)ctx
{
    CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
    CGContextMoveToPoint(ctx, anchor.position.x, anchor.position.y);
    CGContextAddLineToPoint(ctx, particle.position.x, particle.position.y);
    CGContextDrawPath(ctx, kCGPathStroke);
}

- (void)layoutSublayers
{
    if (!CGSizeEqualToSize(self.bounds.size, lastSize)) {
        CGPoint anchorPosition = CGPointMake(roundf(CGRectGetMidX(self.bounds)), roundf(CGRectGetMidY(self.bounds)));
        anchorLayer.position = anchorPosition;
        particleLayer.position = anchorPosition;
        
        anchor.position = CMTPVector3DMake(anchorPosition.x, anchorPosition.y, 0.0f);
        particle.position = anchor.position;
        attractor.position = anchor.position;
        
        lastSize = self.bounds.size;
    }
    
    /* Disable implicit animations */
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    particleLayer.position = CGPointMake(particle.position.x, particle.position.y);
    touchIndicatorLayer.position = CGPointMake(attractor.position.x, attractor.position.y);
    [CATransaction commit];
}

- (id)init
{
    self = [super init];
    if (self) {
        lastSize = self.bounds.size;
        CGPoint anchorPosition = CGPointMake(roundf(CGRectGetMidX(self.bounds)), roundf(CGRectGetMidY(self.bounds)));
        
        /* Init Physics */
        CMTPVector3D gravity = CMTPVector3DMake(0.0f, 0.0f, 0.0f);
        s = [[CMTPParticleSystem alloc] initWithGravityVector:gravity drag:0.3f];
        
        anchor = [[s makeParticleWithMass:1.0f position:CMTPVector3DMake(anchorPosition.x, anchorPosition.y, 0.0f)] retain];
        [anchor makeFixed];
        
        particle = [[s makeParticleWithMass:1.0f position:CMTPVector3DMake(anchorPosition.x, anchorPosition.y, 0.0f)] retain];
        
        attractor = [[s makeParticleWithMass:1.0f position:CMTPVector3DMake(anchorPosition.x, anchorPosition.y, 0.0f)] retain];
        [attractor makeFixed];
        
        spring = [[s makeSpringBetweenParticleA:anchor particleB:particle springConstant:0.1f damping:0.01f restLength:0.0f] retain];
        attraction = [[s makeAttractionBetweenParticleA:attractor particleB:particle strength:9000.0f minDistance:30.0f] retain];
        [attraction turnOff];
        
        /* Sub Layers */
        anchorLayer = [[CMTPDATAnchorLayer alloc] init];
        anchorLayer.frame = CGRectMake(0.0f, 0.0f, 15.0f, 15.0f);
        anchorLayer.position = anchorPosition;
        [self addSublayer:anchorLayer];
        
        particleLayer = [[CMTPDATParticleLayer alloc] init];
        particleLayer.frame = CGRectMake(0.0f, 0.0f, 25.0f, 25.0f);
        particleLayer.position = anchorPosition;
        [self addSublayer:particleLayer];
        
        touchIndicatorLayer = [[CMTPDATTouchIndicatorLayer alloc] init];
        touchIndicatorLayer.frame = CGRectMake(0.0f, 0.0f, 80.0f, 80.0f);
        touchIndicatorLayer.position = anchorPosition;
        touchIndicatorLayer.opacity = 0.0f;
        [self addSublayer:touchIndicatorLayer];
    }
    return self;
}

- (void)dealloc
{
    [displayLink invalidate];
    [displayLink release];
    
    [_fpsLabel release];
    
    [anchor release];
    [anchorLayer release];
    [attraction release];
    [attractor release];
    [particle release];
    [particleLayer release];
    [s release];
    [spring release];
    [touchIndicatorLayer release];
    
    [super dealloc];
}

@end
