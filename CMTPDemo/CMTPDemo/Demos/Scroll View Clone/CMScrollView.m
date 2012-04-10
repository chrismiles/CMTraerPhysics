//
//  CMScrollView.m
//  CMTPDemo
//
//  Created by Chris Miles on 5/03/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "CMScrollView.h"
#import "CMTraerPhysics.h"


#define kSpringDamping 1.1f
#define kMinScrollVelocity 0.1f


static char CMScrollViewOriginKey;


@interface CMScrollView () {
    BOOL _animating;
    CADisplayLink *_displayLink;
    BOOL _isTouching;
    CGPoint _touchLocation;
    CGPoint _touchStartLocation;
    CGPoint _touchVelocity;
    
    CMTPParticle *_fixedParticle;
    CMTPParticleSystem *_particleSystem;
    CMTPParticle *_contentParticle;
    CMTPSpring *_spring1;
    CMTPSpring *_spring2;
    CMTPParticle *_touchParticle;
}

- (void)setupDefaults;
@end


@implementation CMScrollView

@synthesize contentOffset = _contentOffset;
@synthesize contentSize = _contentSize;
@synthesize fixedSpringConstant = _fixedSpringConstant;
@synthesize touchSpringConstant = _touchSpringConstant;

@dynamic scrollDrag;


#pragma mark - Object lifecycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
	[self setupDefaults];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDefaults];
    }
    return self;
}

- (void)setupDefaults
{
    _contentOffset = CGPointZero;
    _contentSize = CGSizeZero;
    
    _fixedSpringConstant = 0.4f;
    _touchSpringConstant = 0.4f;
    
    _particleSystem = [[CMTPParticleSystem alloc] initWithGravityVector:CMTPVector3DMake(0.0f, 0.0f, 0.0f) drag:0.1f];
    _contentParticle = [[_particleSystem makeParticleWithMass:1.0f position:CMTPVector3DMake(0.0f, 0.0f, 0.0f)] retain];
    _fixedParticle = [[_particleSystem makeParticleWithMass:1.0f position:CMTPVector3DMake(0.0f, 0.0f, 0.0f)] retain];
    _touchParticle = [[_particleSystem makeParticleWithMass:1.0f position:CMTPVector3DMake(0.0f, 0.0f, 0.0f)] retain];
    [_fixedParticle makeFixed];
    [_touchParticle makeFixed];
    
    UIPanGestureRecognizer *panGestureRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerAction:)] autorelease];
    [self addGestureRecognizer:panGestureRecognizer];
    
    [self startAnimation];
}

- (void)dealloc
{
    [_displayLink invalidate];
    [_displayLink release]; _displayLink = nil;

    [_fixedParticle release];
    [_particleSystem release];
    [_contentParticle release];
    [_spring1 release];
    [_spring2 release];
    [_touchParticle release];
    
    [super dealloc];
}


#pragma mark - Custom accessors

- (void)setScrollDrag:(float)scrollDrag
{
    _particleSystem.drag = scrollDrag;
}

- (float)scrollDrag
{
    return _particleSystem.drag;
}

- (float)fixedSpringConstant
{
    return _fixedSpringConstant;
}

- (void)setFixedSpringConstant:(float)fixedSpringConstant
{
    _fixedSpringConstant = fixedSpringConstant;
    if (_spring1) {
	_spring1.springConstant = fixedSpringConstant;
    }
}

- (float)touchSpringConstant
{
    return _touchSpringConstant;
}

- (void)setTouchSpringConstant:(float)touchSpringConstant
{
    _touchSpringConstant = touchSpringConstant;
    if (_spring2) {
	_spring2.springConstant = touchSpringConstant;
    }
}


#pragma mark - Gesture recognizers

- (void)panGestureRecognizerAction:(UIPanGestureRecognizer *)panGestureRecognizer
{
    if (UIGestureRecognizerStateBegan == panGestureRecognizer.state) {
	CGPoint location = [panGestureRecognizer locationOfTouch:0 inView:self];
	_touchStartLocation = location;
	_touchLocation = location;
	_isTouching = YES;
	
	_touchVelocity = CGPointZero;
    }
    else if (UIGestureRecognizerStateChanged == panGestureRecognizer.state) {
	CGPoint location = [panGestureRecognizer locationOfTouch:0 inView:self];
	
	// TODO: handles Y scrolling only
	CGPoint touchOffset = CGPointMake(0.0f, location.y - _touchLocation.y);
	_contentParticle.position = CMTPVector3DMake(0.0f, _contentOffset.y + touchOffset.y, 0.0f);
	_touchLocation = location;
    }
    else if (UIGestureRecognizerStateEnded == panGestureRecognizer.state || UIGestureRecognizerStateCancelled == panGestureRecognizer.state) {
	_isTouching = NO;
	_touchVelocity = [panGestureRecognizer velocityInView:self];
    }
}


#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _contentParticle.velocity = CMTPVector3DMake(0.0f, 0.0f, 0.0f);
}


#pragma mark - Private methods

- (void)updateSubviewPositions
{
    //DLog(@"_contentOffset: %@", NSStringFromCGPoint(_contentOffset));
    
    for (UIView *subview in self.subviews) {
	CGPoint origin;
	NSString *originEncoded = objc_getAssociatedObject(subview, &CMScrollViewOriginKey);
	if (originEncoded) {
	    origin = CGPointFromString(originEncoded);
	}
	else {
	    origin = subview.frame.origin;
	    objc_setAssociatedObject(subview, &CMScrollViewOriginKey, NSStringFromCGPoint(origin), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	// Adjust view origin
	CGRect frame = subview.frame;
	frame.origin = CGPointMake(floorf(origin.x + _contentOffset.x), floorf(origin.y + _contentOffset.y));
	subview.frame = frame;
    }
}

- (void)addSpring1
{
    if (nil == _spring1) {
	_spring1 = [[_particleSystem makeSpringBetweenParticleA:_fixedParticle particleB:_contentParticle springConstant:_fixedSpringConstant damping:kSpringDamping restLength:0.0f] retain];
    }
}

- (void)addSpring2
{
    if (nil == _spring2) {
	_spring2 = [[_particleSystem makeSpringBetweenParticleA:_contentParticle particleB:_touchParticle springConstant:_touchSpringConstant damping:kSpringDamping restLength:0.0f] retain];
    }
}

- (void)removeSpring1
{
    if (_spring1) {
	[_particleSystem removeSpringByReference:_spring1];
	[_spring1 release]; _spring1 = nil;
    }
}

- (void)removeSpring2
{
    if (_spring2) {
	[_particleSystem removeSpringByReference:_spring2];
	[_spring2 release]; _spring2 = nil;
    }
}

- (void)removeSprings
{
    [self removeSpring1];
    [self removeSpring2];
}

- (void)configureSpringsForElasticityAtTop:(BOOL)atTop
{
    [self addSpring1];
    
    CGFloat contentTopY = CGRectGetHeight(self.bounds) - self.contentSize.height;
    _fixedParticle.position = CMTPVector3DMake(0.0f, (atTop ? 0.0f : contentTopY), 0.0f);
    
    if (_isTouching) {
	[self addSpring2];
	_touchParticle.position = CMTPVector3DMake(0.0f, _fixedParticle.position.y + (_touchLocation.y - _touchStartLocation.y), 0.0f);
    }
    else {
	[self removeSpring2];
    }
}

- (void)updatePhysics
{
    CGFloat contentTopY = CGRectGetHeight(self.bounds) - self.contentSize.height;
    
    if (_contentParticle.position.y > 0.0f) {
	// Rubber banding at top
	[self configureSpringsForElasticityAtTop:YES];
    }
    else if (_contentParticle.position.y < contentTopY) {
	// Rubber banding at bottom
	[self configureSpringsForElasticityAtTop:NO];
    }
    else {
	// No rubber banding
	[self removeSprings];
    }
    
    if (NO == _isTouching && _touchVelocity.y != 0.0f) {
	// Apply momentum after touch up, if magnitude is large enough
	if (fabsf(_touchVelocity.y) > 50.0f) {
	    _contentParticle.velocity = CMTPVector3DMake(0.0f, _touchVelocity.y*0.05f, 0.0f);
	}
	_touchVelocity = CGPointZero;
    }
}


#pragma mark - Animation

- (void)startAnimation
{
    if (nil == _displayLink) {
	/* Init Timer */
	_displayLink = [[CADisplayLink displayLinkWithTarget:self selector:@selector(drawFrame:)] retain];
	[_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopAnimation
{
    if (_displayLink) {
	[_displayLink invalidate];
	[_displayLink release];
	_displayLink = nil;
    }
}

- (void)drawFrame:(CADisplayLink *)displayLink
{
    //CFTimeInterval step = displayLink.duration * displayLink.frameInterval;
    CFTimeInterval step = 0.5f;

    [self updatePhysics];
    
    [_particleSystem tick:(float)step];
    
    _contentOffset = CGPointMake(0.0f, _contentParticle.position.y);
    [self updateSubviewPositions];
    
    float velocityYMagnitude = fabsf(_contentParticle.velocity.y);
    if (velocityYMagnitude > 0.0f && velocityYMagnitude < kMinScrollVelocity) {
	_contentParticle.velocity = CMTPVector3DMake(0.0f, 0.0f, 0.0f);
    }
}

@end
