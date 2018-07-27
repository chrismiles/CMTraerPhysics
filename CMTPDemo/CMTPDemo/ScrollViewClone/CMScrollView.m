//
//  CMScrollView.m
//  CMTPDemo
//
//  Created by Chris Miles on 5/03/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
//

#import "CMScrollView.h"
#import "CMTraerPhysics.h"
#import "CMGLESKUtil.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

#define kSpringDamping 1.1f
#define kMinScrollVelocity 0.1f

static char CMScrollViewOriginKey;

@interface CMScrollView () {
    BOOL _animating;
    BOOL _isTouching;
    CGPoint _touchLocation;
    CGPoint _touchStartLocation;
    CGPoint _touchVelocity;

}
@property (strong,nonatomic) CADisplayLink* displayLink;

@property (strong,nonatomic) CMTPParticle* fixedParticle;
@property (strong,nonatomic) CMTPParticleSystem* particleSystem;
@property (strong,nonatomic) CMTPParticle* contentParticle;
@property (strong,nonatomic) CMTPSpring* spring1;
@property (strong,nonatomic) CMTPSpring* spring2;
@property (strong,nonatomic) CMTPParticle* touchParticle;
@end

@implementation CMScrollView

@synthesize fixedSpringConstant=_fixedSpringConstant;
@synthesize touchSpringConstant=_touchSpringConstant;

@dynamic scrollDrag;

#pragma mark - Object lifecycle

-(id)initWithFrame:(CGRect)frame {
    self=[super initWithFrame:frame];
    if (self) {
        [self setupDefaults];
    }
    return self;
}

-(id)initWithCoder:(NSCoder*)coder {
    self=[super initWithCoder:coder];
    if (self) {
        [self setupDefaults];
    }
    return self;
}

-(void)setupDefaults {
    _contentOffset=CGPointZero;
    _contentSize=CGSizeZero;

    _fixedSpringConstant=0.4f;
    _touchSpringConstant=0.4f;

    _particleSystem=[[CMTPParticleSystem alloc] initWithGravityVector:CMTPVector3DMake(0.0f,0.0f,0.0f) drag:0.1f];
    _contentParticle=[_particleSystem makeParticleWithMass:1.0f position:CMTPVector3DMake(0.0f,0.0f,0.0f)];
    _fixedParticle=[_particleSystem makeParticleWithMass:1.0f position:CMTPVector3DMake(0.0f,0.0f,0.0f)];
    _touchParticle=[_particleSystem makeParticleWithMass:1.0f position:CMTPVector3DMake(0.0f,0.0f,0.0f)];
    [_fixedParticle makeFixed];
    [_touchParticle makeFixed];

    UIPanGestureRecognizer* panGestureRecognizer=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerAction:)];
    [self addGestureRecognizer:panGestureRecognizer];

    [self startAnimation];
}

-(void)dealloc {
    [_displayLink invalidate];
}

#pragma mark - Custom accessors

-(void)setScrollDrag:(CMTPFloat)scrollDrag {
    _particleSystem.drag=scrollDrag;
}

-(CMTPFloat)scrollDrag {
    return _particleSystem.drag;
}

-(CMTPFloat)fixedSpringConstant {
    return _fixedSpringConstant;
}

-(void)setFixedSpringConstant:(CMTPFloat)fixedSpringConstant {
    _fixedSpringConstant=fixedSpringConstant;
    if (_spring1) {
        _spring1.springConstant=fixedSpringConstant;
    }
}

-(CMTPFloat)touchSpringConstant {
    return _touchSpringConstant;
}

-(void)setTouchSpringConstant:(CMTPFloat)touchSpringConstant {
    _touchSpringConstant=touchSpringConstant;
    if (_spring2) {
        _spring2.springConstant=touchSpringConstant;
    }
}

#pragma mark - Gesture recognizers

-(void)panGestureRecognizerAction:(UIPanGestureRecognizer*)panGestureRecognizer {
    if (UIGestureRecognizerStateBegan==panGestureRecognizer.state) {
        CGPoint location=[panGestureRecognizer locationOfTouch:0 inView:self];
        _touchStartLocation=location;
        _touchLocation=location;
        _isTouching=YES;

        _touchVelocity=CGPointZero;
    } else if (UIGestureRecognizerStateChanged==panGestureRecognizer.state) {
        CGPoint location=[panGestureRecognizer locationOfTouch:0 inView:self];

        // TODO: handles Y scrolling only
        CGPoint touchOffset=CGPointMake(0.0f,location.y-_touchLocation.y);
        _contentParticle.position=CMTPVector3DMake(0.0f,_contentOffset.y+touchOffset.y,0.0f);
        _touchLocation=location;
    } else if (UIGestureRecognizerStateEnded==panGestureRecognizer.state||UIGestureRecognizerStateCancelled==panGestureRecognizer.state) {
        _isTouching=NO;
        _touchVelocity=[panGestureRecognizer velocityInView:self];
    }
}

#pragma mark - Touch handling

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    _contentParticle.velocity=CMTPVector3DMake(0.0f,0.0f,0.0f);
}

#pragma mark - Private methods

-(void)updateSubviewPositions {
    //DLog(@"_contentOffset: %@", NSStringFromCGPoint(_contentOffset));
    for (UIView* subview in self.subviews) {
        CGPoint origin;
        NSString* originEncoded=objc_getAssociatedObject(subview,&CMScrollViewOriginKey);
        if (originEncoded) {
            origin=CGPointFromString(originEncoded);
        } else {
            origin=subview.frame.origin;
            objc_setAssociatedObject(subview,&CMScrollViewOriginKey,NSStringFromCGPoint(origin),OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        // Adjust view origin
        CGRect frame=subview.frame;
        frame.origin=CGPointMake(floor(origin.x+_contentOffset.x),floor(origin.y+_contentOffset.y));
        subview.frame=frame;
    }
}

-(void)addSpring1 {
    if (nil==_spring1) {
        _spring1=[_particleSystem makeSpringBetweenParticleA:_fixedParticle particleB:_contentParticle springConstant:_fixedSpringConstant damping:kSpringDamping restLength:0.0f];
    }
}

-(void)addSpring2 {
    if (nil==_spring2) {
        _spring2=[_particleSystem makeSpringBetweenParticleA:_contentParticle particleB:_touchParticle springConstant:_touchSpringConstant damping:kSpringDamping restLength:0.0f];
    }
}

-(void)removeSpring1 {
    if (_spring1) {
        [_particleSystem removeSpringByReference:_spring1];
        _spring1=nil;
    }
}

-(void)removeSpring2 {
    if (_spring2) {
        [_particleSystem removeSpringByReference:_spring2];
        _spring2=nil;
    }
}

-(void)removeSprings {
    [self removeSpring1];
    [self removeSpring2];
}

-(void)configureSpringsForElasticityAtTop:(BOOL)atTop {
    [self addSpring1];

    CGFloat contentTopY=CGRectGetHeight(self.bounds)-self.contentSize.height;
    _fixedParticle.position=CMTPVector3DMake(0.0f,(atTop?0.0f:contentTopY),0.0f);
    if (_isTouching) {
        [self addSpring2];
        _touchParticle.position=CMTPVector3DMake(0.0f,_fixedParticle.position.y+(_touchLocation.y-_touchStartLocation.y),0.0f);
    } else {
        [self removeSpring2];
    }
}

-(void)updatePhysics {
    CGFloat contentTopY=CGRectGetHeight(self.bounds)-self.contentSize.height;
    if (_contentParticle.position.y>0.0f) {
        // Rubber banding at top
        [self configureSpringsForElasticityAtTop:YES];
    } else if (_contentParticle.position.y<contentTopY) {
        // Rubber banding at bottom
        [self configureSpringsForElasticityAtTop:NO];
    } else {
        // No rubber banding
        [self removeSprings];
    }
    if (NO==_isTouching&&_touchVelocity.y!=0.0f) {
        // Apply momentum after touch up, if magnitude is large enough
        if (fabs(_touchVelocity.y)>50.0f) {
            _contentParticle.velocity=CMTPVector3DMake(0.0f,_touchVelocity.y*0.05f,0.0f);
        }
        _touchVelocity=CGPointZero;
    }
}

#pragma mark - Animation

-(void)startAnimation {
    if (nil==_displayLink) {
        /* Init Timer */
        _displayLink=[CADisplayLink displayLinkWithTarget:self selector:@selector(drawFrame:)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

-(void)stopAnimation {
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink=nil;
    }
}

-(void)drawFrame:(CADisplayLink*)displayLink {
    //CFTimeInterval step = displayLink.duration * displayLink.frameInterval;
    CFTimeInterval step=0.5f;

    [self updatePhysics];

    [_particleSystem tick:(CMTPFloat)step];

    _contentOffset=CGPointMake(0.0f,_contentParticle.position.y);
    [self updateSubviewPositions];

    CMTPFloat velocityYMagnitude=fabs(_contentParticle.velocity.y);
    if (velocityYMagnitude>0.0f&&velocityYMagnitude<kMinScrollVelocity) {
        _contentParticle.velocity=CMTPVector3DMake(0.0f,0.0f,0.0f);
    }
}

@end

