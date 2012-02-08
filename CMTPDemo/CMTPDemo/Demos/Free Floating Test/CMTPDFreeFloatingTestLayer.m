//
//  CMTPDFreeFloatingTestLayer.m
//  CMTPDemo
//
//  Created by Chris Miles on 12/12/11.
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

#import "CMTPDFreeFloatingTestLayer.h"
#import "CMTraerPhysics.h"
#import "CMTPDFreeFloatingTestSubLayer.h"


/* Return a random float between 0.0 and 1.0 */
static float randomClamp()
{
    return (float)(arc4random() % ((unsigned)RAND_MAX + 1)) / (float)((unsigned)RAND_MAX + 1);
}

static CGFloat CGPointDistance(CGPoint userPosition, CGPoint prevPosition)
{
    CGFloat dx = prevPosition.x - userPosition.x;
    CGFloat dy = prevPosition.y - userPosition.y;
    return sqrtf(dx*dx + dy*dy);
}


@interface CMTPDFreeFloatingTestLayer () {
    
    NSUInteger numParticles;
    
    CADisplayLink *displayLink;
    CGSize lastSize;
    CGPoint prevPosition;
    CGPoint userPosition;

    /* Physics */
    CMTPParticle *attractor;
    NSMutableArray *attractions;
    float attractorStrengthFactor;
    NSMutableArray *particles;
    CMTPParticleSystem *s;
    
    // FPS
    double fps_prev_time;
    NSUInteger fps_count;
}

@end


@implementation CMTPDFreeFloatingTestLayer

@synthesize fpsLabel=_fpsLabel;

- (NSUInteger)particleCount
{
    return numParticles;
}

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
    userPosition = position;
}

- (void)clearPrevPosition
{
    prevPosition = userPosition;
}

- (void)drawFrame:(CADisplayLink *)sender
{
    [s tick:1];
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

- (void)generateParticles
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].scale == 1) {
	// Significantly less particles on earlier iPhones (i.e. 3GS) to keep acceptable performance
	numParticles = 100;
    }
    else {
	numParticles = 500;
    }
    
    CGFloat particleSize;
    float attractorStrength;
    float attractorMinDistance;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
	attractorStrength = 100.0f;
	attractorMinDistance = 30.0f;
	attractorStrengthFactor = 60.0f;
	particleSize = 14.0f;
    }
    else {
	attractorStrength = 50.0f;
	attractorMinDistance = 15.0f;
	attractorStrengthFactor = 30.0f;
	particleSize = 10.0f;
    }
    
    attractor = [[s makeParticleWithMass:0.8f position:CMTPVector3DMake(0, 0, 0)] retain];
    
    for (unsigned int i = 0; i<numParticles; i++) {
	float randx = randomClamp() * (CGRectGetWidth(self.bounds)-1);
	float randy = randomClamp() * (CGRectGetHeight(self.bounds)-1);
	
	CMTPDFreeFloatingTestSubLayer *subLayer = [[CMTPDFreeFloatingTestSubLayer alloc] init];
	subLayer.frame = CGRectMake(0.0f, 0.0f, particleSize, particleSize);
	subLayer.position = CGPointMake(randx, randy);
	[self addSublayer:subLayer];
	
	CMTPParticle *particle = [s makeParticleWithMass:0.8f position:CMTPVector3DMake(randx, randy, 0)];
	particle.context = subLayer;
	[particles addObject:particle];
	
	[subLayer release];
	
	CMTPAttraction *attraction = [s makeAttractionBetweenParticleA:particle particleB:attractor strength:attractorStrength minDistance:attractorMinDistance];
	[attractions addObject:attraction];
    }
}


#pragma mark - CALayer methods

- (void)layoutSublayers
{
    if (!CGSizeEqualToSize(self.bounds.size, lastSize) && !attractor) {
	[self generateParticles];

        lastSize = self.bounds.size;
    }
    
    /* Disable implicit animations */
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    attractor.position = CMTPVector3DMake(userPosition.x, userPosition.y, 0.0f);
    
    float width = CGRectGetWidth(self.bounds);
    float height = CGRectGetHeight(self.bounds);
    
    for (unsigned int i=0; i < numParticles; i++) {
	CMTPParticle *particle = [particles objectAtIndex:i];
	float x = fmodf(width + particle.position.x, width);
	float y = fmodf(height + particle.position.y, height);
	particle.position = CMTPVector3DMake(x, y, 0);
	
	CMTPDFreeFloatingTestSubLayer *sublayer = particle.context;
	sublayer.position = CGPointMake(x, y);
	
	if (prevPosition.x >= 0.0f) {
	    float distance = CGPointDistance(userPosition, prevPosition);
	    CMTPAttraction *attraction = [attractions objectAtIndex:i];
	    [attraction setMinDistance:distance*1.2f];
	    [attraction setStrength:-(10 + (attractorStrengthFactor * (distance*distance)))];
	}
    }
    
    prevPosition = userPosition;

    [CATransaction commit];
}


#pragma mark - Object lifecycle

- (id)init
{
    self = [super init];
    if (self) {
	self.contentsScale = [UIScreen mainScreen].scale;

	lastSize = self.bounds.size;
	userPosition = CGPointZero;
	prevPosition = CGPointMake(-1.0f, -1.0f);

        /* Init Physics */
        CMTPVector3D gravity = CMTPVector3DMake(0.0f, 0.0f, 0.0f);
        s = [[CMTPParticleSystem alloc] initWithGravityVector:gravity drag:0.02f];
	[s setIntegrator:CMTPParticleSystemIntegratorModifiedEuler];	// faster simulation (but less stable)

        attractions = [[NSMutableArray alloc] init];
	particles = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [displayLink invalidate];
    [displayLink release]; displayLink = nil;
    
    [_fpsLabel release];
    [attractions release];
    [attractor release];
    [particles release];
    [s release];
    
    [super dealloc];
}

@end
