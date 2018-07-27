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
#import "CMTPDATSubLayers.h"
#import "CMTraerPhysics.h"

@interface CMTPDAttractionTestLayer () {
    CGSize lastSize;

    // FPS
    double fps_prev_time;
    NSUInteger fps_count;
}

@property (strong,nonatomic) CADisplayLink* displayLink;

/* Sub Layers */
@property (strong,nonatomic) CMTPDATAnchorLayer* anchorLayer;
@property (strong,nonatomic) CMTPDATParticleLayer* particleLayer;
@property (strong,nonatomic) CMTPDATTouchIndicatorLayer* touchIndicatorLayer;

/* Physics */
@property (strong,nonatomic) CMTPAttraction* attraction;
@property (strong,nonatomic) CMTPParticle* anchor;
@property (strong,nonatomic) CMTPParticle* attractor;
@property (strong,nonatomic) CMTPParticle* particle;
@property (strong,nonatomic) CMTPSpring* spring;
@property (strong,nonatomic) CMTPParticleSystem* s;
@end

@implementation CMTPDAttractionTestLayer

-(void)startAnimation {
    if (nil==_displayLink) {
        /* Init Timer */
        self.displayLink=[CADisplayLink displayLinkWithTarget:self selector:@selector(drawFrame:)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

-(void)stopAnimation {
    if (_displayLink) {
        [_displayLink invalidate];
        self.displayLink=nil;
    }
}

-(void)setUserPosition:(CGPoint)position {
    _attractor.position=CMTPVector3DMake(position.x,position.y,0.0f);
    [_attraction turnOn];
    _touchIndicatorLayer.opacity=1.0f;
}

-(void)clearUserPosition {
    [_attraction turnOff];
    _touchIndicatorLayer.opacity=0.0f;
}

-(void)drawFrame:(CADisplayLink*)sender {
    [_s tick:1];
    [self setNeedsDisplay];     // draw "spring" line
    [self setNeedsLayout];      // position sub layers
    /* FPS */
    if (_fpsLabel) {
        double curr_time=CACurrentMediaTime();
        if (curr_time-fps_prev_time>=0.2) {
            double delta=(curr_time-fps_prev_time)/fps_count;
            _fpsLabel.title=[NSString stringWithFormat:@"%0.0f fps",1.0/delta];
            fps_prev_time=curr_time;
            fps_count=1;
        } else {
            fps_count++;
        }
    }
}

-(void)drawInContext:(CGContextRef)ctx {
    CGContextSetStrokeColorWithColor(ctx,[UIColor redColor].CGColor);
    CGContextMoveToPoint(ctx,_anchor.position.x,_anchor.position.y);
    CGContextAddLineToPoint(ctx,_particle.position.x,_particle.position.y);
    CGContextDrawPath(ctx,kCGPathStroke);
}

-(void)layoutSublayers {
    if (!CGSizeEqualToSize(self.bounds.size,lastSize)) {
        CGPoint anchorPosition=CGPointMake(round(CGRectGetMidX(self.bounds)),round(CGRectGetMidY(self.bounds)));
        _anchorLayer.position=anchorPosition;
        _particleLayer.position=anchorPosition;

        _anchor.position=CMTPVector3DMake(anchorPosition.x,anchorPosition.y,0.0f);
        _particle.position=_anchor.position;
        _attractor.position=_anchor.position;

        lastSize=self.bounds.size;
    }
    /* Disable implicit animations */
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    _particleLayer.position=CGPointMake(_particle.position.x,_particle.position.y);
    _touchIndicatorLayer.position=CGPointMake(_attractor.position.x,_attractor.position.y);
    [CATransaction commit];
}

-(id)init {
    self=[super init];
    if (self) {
        lastSize=self.bounds.size;
        CGPoint anchorPosition=CGPointMake(round(CGRectGetMidX(self.bounds)),round(CGRectGetMidY(self.bounds)));

        /* Init Physics */
        CMTPVector3D gravity=CMTPVector3DMake(0.0f,0.0f,0.0f);
        self.s=[[CMTPParticleSystem alloc] initWithGravityVector:gravity drag:0.3f];

        self.anchor=[_s makeParticleWithMass:1.0f position:CMTPVector3DMake(anchorPosition.x,anchorPosition.y,0.0f)];
        [_anchor makeFixed];

        self.particle=[_s makeParticleWithMass:1.0f position:CMTPVector3DMake(anchorPosition.x,anchorPosition.y,0.0f)];

        self.attractor=[_s makeParticleWithMass:1.0f position:CMTPVector3DMake(anchorPosition.x,anchorPosition.y,0.0f)];
        [_attractor makeFixed];

        self.spring=[_s makeSpringBetweenParticleA:_anchor particleB:_particle springConstant:0.1f damping:0.01f restLength:0.0f];
        self.attraction=[_s makeAttractionBetweenParticleA:_attractor particleB:_particle strength:9000.0f minDistance:30.0f];
        [_attraction turnOff];

        /* Sub Layers */
        self.anchorLayer=[[CMTPDATAnchorLayer alloc] init];
        _anchorLayer.frame=CGRectMake(0.0f,0.0f,15.0f,15.0f);
        _anchorLayer.position=anchorPosition;
        [self addSublayer:_anchorLayer];

        self.particleLayer=[[CMTPDATParticleLayer alloc] init];
        _particleLayer.frame=CGRectMake(0.0f,0.0f,25.0f,25.0f);
        _particleLayer.position=anchorPosition;
        [self addSublayer:_particleLayer];

        self.touchIndicatorLayer=[[CMTPDATTouchIndicatorLayer alloc] init];
        _touchIndicatorLayer.frame=CGRectMake(0.0f,0.0f,80.0f,80.0f);
        _touchIndicatorLayer.position=anchorPosition;
        _touchIndicatorLayer.opacity=0.0f;
        [self addSublayer:_touchIndicatorLayer];
    }
    return self;
}

-(void)dealloc {
    [_displayLink invalidate];
}

@end

