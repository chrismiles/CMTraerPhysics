//
//  CMTPDSpringTestLayer.m
//  CMTPDemo
//
//  Created by Chris Miles on 15/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import "CMTPDSpringTestLayer.h"
#import "CMTPParticleSystem.h"
#import "CMTPDSmoothedPath.h"

#define kHandleRadius 5.0f


static CGFloat CGPointDistance(CGPoint userPosition, CGPoint prevPosition)
{
    CGFloat dx = prevPosition.x - userPosition.x;
    CGFloat dy = prevPosition.y - userPosition.y;
    return sqrtf(dx*dx + dy*dy);
}


@interface CMTPDSpringTestLayer () {
    double spring_length;
    NSUInteger subdivisions;

    CADisplayLink *displayLink;
    CGPoint handle;
    BOOL isDragging;
    CGSize lastSize;
    
    float gravityScale;
    CMMotionManager *motionManager;

    /* Physics */
    CMTPParticle *anchor;
    NSMutableArray *particles;
    CMTPParticleSystem *s;
    
    // FPS
    double fps_prev_time;
    NSUInteger fps_count;
}

@end


@implementation CMTPDSpringTestLayer

@dynamic isDeviceMotionAvailable;
@dynamic gravityByDeviceMotionEnabled;
@synthesize fpsLabel=_fpsLabel;
@synthesize smoothed;

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

- (void)drawFrame:(CADisplayLink *)sender
{
    if (motionManager.isDeviceMotionActive) {
        CMAcceleration gravity = motionManager.deviceMotion.gravity;
        CMTPVector3D gravityVector = CMTPVector3DMake(gravity.x*gravityScale, -gravity.y*gravityScale, 0.0f);
        s.gravity = gravityVector;
    }

    [s tick:1.8];
    [self setNeedsDisplay];      // draw layer
    
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
    anchor = [[s makeParticleWithMass:0.8f position:CMTPVector3DMake(CGRectGetMidX(self.bounds), CGRectGetHeight(self.bounds)*0.2f, 0)] retain];
    [anchor makeFixed];
    [particles addObject:anchor];
    
    double sub_len = spring_length / subdivisions;
    float sy = 100.0f;
    for (NSUInteger i=1; i<=subdivisions; i++) {
	CMTPParticle *p = [s makeParticleWithMass:0.6f position:CMTPVector3DMake(300, sy + i*sub_len, 0)];
	[particles addObject:p];
    }
    
    for (NSUInteger i=0; i<[particles count]-1; i++)  {
	[s makeSpringBetweenParticleA:[particles objectAtIndex:i] particleB:[particles objectAtIndex:i+1] springConstant:0.5f damping:0.2f restLength:sub_len];
    } 
}


#pragma mark - Custom property accessors

- (BOOL)isDeviceMotionAvailable
{
    return motionManager.isDeviceMotionAvailable;
}

- (void)setGravityByDeviceMotionEnabled:(BOOL)gravityByDeviceMotionEnabled
{
    if (gravityByDeviceMotionEnabled) {
        if ([motionManager isDeviceMotionAvailable]) {
            [motionManager startDeviceMotionUpdates];
        }
    }
    else {
        if ([motionManager isDeviceMotionActive]) {
            [motionManager stopDeviceMotionUpdates];
        }
    }
}

- (BOOL)gravityByDeviceMotionEnabled
{
    return [motionManager isDeviceMotionActive];
}


#pragma mark - Handle touches

- (void)touchBeganAtLocation:(CGPoint)location
{
    if (CGPointDistance(location, handle) <= 40.0f) {
	isDragging = YES;
	handle = location;
    }
}

- (void)touchMovedAtLocation:(CGPoint)location
{
    if (isDragging) {
	handle = location;
    }
}

- (void)touchEndedAtLocation:(CGPoint)location
{
    if (isDragging) {
	handle = location;
	isDragging = NO;
    }
}

- (void)touchCancelledAtLocation:(CGPoint)location
{
    if (isDragging) {
	isDragging = NO;
    }
}


#pragma mark - CALayer methods

- (void)drawInContext:(CGContextRef)ctx
{
    if (!CGSizeEqualToSize(self.bounds.size, lastSize) && !anchor) {
	[self generateParticles];
	
	gravityScale = 1.0f * CGRectGetHeight(self.frame) / 320.0f;
        lastSize = self.bounds.size;
    }
    
    CMTPParticle *p = [particles objectAtIndex:subdivisions];
    if (!isDragging) {
	[p makeFree];
	
	handle.x = p.position.x;
	handle.y = p.position.y;
    } else {
	[p makeFixed];
	
	p.position = CMTPVector3DMake(handle.x, handle.y, 0.0f);
    }
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    p = [particles objectAtIndex:0];
    CGPathMoveToPoint(path, NULL, p.position.x, p.position.y);
    for (int i=1; i<[particles count]; i++) {
	p = [particles objectAtIndex:i];
	CGPathAddLineToPoint(path, NULL, p.position.x, p.position.y);
    }
    
    UIGraphicsPushContext(ctx);
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithCGPath:path];
    if (smoothed) {
	bezierPath = smoothedPath(bezierPath, 8);
    }
    [bezierPath stroke];
    UIGraphicsPopContext();
    
    CGPathRelease(path);
    
    CGContextAddEllipseInRect(ctx, CGRectMake(handle.x-kHandleRadius, handle.y-kHandleRadius, kHandleRadius*2, kHandleRadius*2));
    CGContextStrokePath(ctx);
}


#pragma mark - Object lifecycle

- (id)init
{
    self = [super init];
    if (self) {
	self.contentsScale = [UIScreen mainScreen].scale;
	
	lastSize = self.bounds.size;
	handle = CGPointZero;
	
	//	spring_length = 70.0;
	//	subdivisions = 5;
	spring_length = 25.0;
	subdivisions = 8;

	motionManager = [[CMMotionManager alloc] init];
        motionManager.deviceMotionUpdateInterval = 0.02; // 50 Hz

        /* Init Physics */
        CMTPVector3D gravity = CMTPVector3DMake(0.0f, 2.0f, 0.0f);
        s = [[CMTPParticleSystem alloc] initWithGravityVector:gravity drag:0.15f];
	
	particles = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [displayLink invalidate];
    [displayLink release];
    
    [_fpsLabel release];
    [anchor release];
    [motionManager release];
    [particles release];
    [s release];
    
    [super dealloc];
}

@end
