//
//  CMTPParticleSystem.m
//  CMTraerPhysics
//
//  Traer v3.0 physics engine, Objective-C port
//  Objective-C port by Chris Miles, http://chrismiles.info/
//  Ported from the AS3 port. AS3 port by Arnaud Icard, http://blog.sqrtof5.com, http://github.com/sqrtof5
//  Originally created by Jeffrey Traer Bernstein http://murderandcreate.com/physics/
//
//  Created by Chris Miles, 2011.
//  Copyright 2011 Chris Miles. All rights reserved.
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

#import "CMTPParticleSystem.h"
#import "CMTPModifiedEulerIntegrator.h"
#import "CMTPRungeKuttaIntegrator.h"

#ifdef DEBUG_PHYSICS_OBJECTS
#import <QuartzCore/QuartzCore.h>	// for CACurrentMediaTime()
#endif


@implementation CMTPParticleSystem

@synthesize gravity, drag, particles;

- (void)setIntegrator:(CMTPParticleSystemIntegrator)anIntegrator
{
    switch (anIntegrator) {
	case CMTPParticleSystemIntegratorRungeKutta:
	    [integrator release];
	    integrator = [[CMTPRungeKuttaIntegrator alloc] initWithParticleSystem:self];
	    break;
	    
	case CMTPParticleSystemIntegratorModifiedEuler:
	    [integrator release];
	    integrator = [[CMTPModifiedEulerIntegrator alloc] initWithParticleSystem:self];
	    break;
    }	
}

- (void)tick:(CMTPFloat)t
{
    [integrator step:t];
    
#ifdef DEBUG_PHYSICS_OBJECTS
    CFTimeInterval curr_time = CACurrentMediaTime();
    if (curr_time - debug_physics_prev_time >= 1.0) {
	DLog(@"PHYSICS OBJECTS DEBUG: #particles=%d  springs=%d  attractions=%d  custom=%d", [particles count], [springs count], [attractions count], [custom count]);
	
	debug_physics_prev_time = curr_time;
    }
#endif
    
}

- (CMTPParticle *)makeParticleWithMass:(CMTPFloat)mass position:(CMTPVector3D)position
{
    CMTPParticle *p = [[CMTPParticle alloc] initWithMass:mass position:position];
    [particles addObject:p];
    return [p autorelease];
}

- (CMTPSpring *)makeSpringBetweenParticleA:(CMTPParticle *)particleA particleB:(CMTPParticle *)particleB springConstant:(CMTPFloat)springConstant damping:(CMTPFloat)damping restLength:(CMTPFloat)restLength
{
    CMTPSpring *s = [[CMTPSpring alloc] initWithParticleA:particleA particleB:particleB springConstant:springConstant damping:damping restLength:restLength];
    [springs addObject:s];
    return [s autorelease];
}

- (CMTPAttraction *)makeAttractionBetweenParticleA:(CMTPParticle *)particleA particleB:(CMTPParticle *)particleB strength:(CMTPFloat)strength minDistance:(CMTPFloat)minDistance
{
    CMTPAttraction *m = [[CMTPAttraction alloc] initWithParticleA:particleA particleB:particleB strength:strength minDistance:minDistance];
    [attractions addObject:m];
    return [m autorelease];
}

- (void)clear
{
    [particles release];
    [springs release];
    [attractions release];
    
    particles = [[NSMutableArray alloc] init];
    springs = [[NSMutableArray alloc] init];
    attractions = [[NSMutableArray alloc] init];	
}

- (void)applyForces
{
    NSUInteger i;
    NSUInteger p_length = [particles count];
    NSUInteger s_length = [springs count];
    NSUInteger a_length = [attractions count];
    NSUInteger c_length = [custom count];
    
    // Effects of gravity
    if ( gravity.x != 0.0f || gravity.y != 0.0f || gravity.x != 0.0f) {
	for (i=0; i<p_length; i++) {
	    CMTPParticle *p = [particles objectAtIndex:i];
	    p.force = CMTPVector3DAdd(p.force, gravity);
	}
    }
    
    for (i=0; i<p_length; i++) {
	CMTPParticle *p = [particles objectAtIndex:i];
	CMTPVector3D vdrag;
	vdrag.x = p.velocity.x;
	vdrag.y = p.velocity.y;
	vdrag.z = p.velocity.z;
	
	vdrag = CMTPVector3DScaleBy(vdrag, -drag);
	//vdrag.scaleBy(-drag);
	p.force = CMTPVector3DAdd(p.force, vdrag);
    }
    
    for (i=0; i<s_length; i++) {
	CMTPSpring *s = [springs objectAtIndex:i];
	[s apply];
    }
    
    for (i=0; i<a_length; i++) {
	CMTPAttraction *a = [attractions objectAtIndex:i];
	[a apply];
    }
    
    for (i=0; i<c_length; i++) {
	CMTPForce *f = [custom objectAtIndex:i];
	[f apply];
    }
}

- (void)clearForces
{
    NSUInteger p_length = [particles count];
    
    for (NSUInteger i=0; i<p_length; i++) {
	CMTPParticle *p = [particles objectAtIndex:i];
	p.force = CMTPVector3DMake(0.0, 0.0, 0.0);
    }
}

- (NSUInteger)numberOfParticles
{
    return [particles count];
}

- (NSUInteger)numberOfSprings
{
    return [springs count];
}

- (NSUInteger)numberOfAttractions
{
    return [attractions count];
}

- (CMTPParticle *)getParticleAtIndex:(NSUInteger)i
{
    return [particles objectAtIndex:i];
}

- (CMTPSpring *)getSpringAtIndex:(NSUInteger)i
{
    return [springs objectAtIndex:i];
}

- (CMTPAttraction *)getAttractionAtIndex:(NSUInteger)i
{
    return [attractions objectAtIndex:i];
}

- (void)addCustomForce:(CMTPForce *)f
{
    [custom addObject:f];
}

- (NSUInteger)numberOfCustomForces
{
    return [custom count];
}

- (CMTPForce *)getCustomForceAtIndex:(NSUInteger)i
{
    return [custom objectAtIndex:i];
}

- (void)removeCustomForceAtIndex:(NSUInteger)i
{
    [custom removeObjectAtIndex:i];
}

- (BOOL)removeCustomForceByReference:(CMTPForce *)f
{
    NSUInteger i;
    NSUInteger n = 0;
    BOOL found = NO;
    NSUInteger c_length = [custom count];
    for (i=0; i<c_length; i++) {
	if ([custom objectAtIndex:i] == f) {
	    n = i;
            found = YES;
	    break;
	}
    }
    if (found) {
	[custom removeObjectAtIndex:n];
	return YES;
    } else {
	return NO;
    }
}

- (void)removeSpringAtIndex:(NSUInteger)i
{
    [springs removeObjectAtIndex:i];
}

- (BOOL)removeSpringByReference:(CMTPSpring *)s
{
    NSUInteger i;
    NSUInteger n = 0;
    BOOL found = NO;
    NSUInteger s_length = [springs count];
    for (i=0; i<s_length; i++) {
	if ([springs objectAtIndex:i] == s) {
	    n = i;
            found = YES;
	    break;
	}
    }
    if (found) {
	[springs removeObjectAtIndex:n];
	return YES;
    } else {
	return NO;
    }
}

- (void)removeAttractionAtIndex:(NSUInteger)i
{
    [attractions removeObjectAtIndex:i];
}

- (BOOL)removeAttractionByReference:(CMTPAttraction *)a
{
    NSUInteger i;
    NSUInteger n = 0;
    BOOL found = NO;
    NSUInteger a_length = [attractions count];
    for (i=0; i<a_length; i++) {
	if ([attractions objectAtIndex:i] == a) {
	    n = i;
            found = YES;
	    break;
	}
    }
    if (found) {
	[attractions removeObjectAtIndex:n];
	return YES;
    } else {
	return NO;
    }
}

- (void)removeParticleAtIndex:(NSUInteger)i
{
    [particles removeObjectAtIndex:i];
}

- (BOOL)removeParticleByReference:(CMTPParticle *)p
{
    NSUInteger i;
    NSUInteger n = 0;
    BOOL found = NO;
    NSUInteger p_length = [particles count];
    for (i=0; i<p_length; i++) {
	if ([particles objectAtIndex:i] == p) {
	    n = i;
            found = YES;
	    break;
	}
    }
    if (found) {
	[particles removeObjectAtIndex:n];
	return YES;
    } else {
	return NO;
    }
}

- (id)initWithGravityVector:(CMTPVector3D)gravityVector drag:(CMTPFloat)dragValue
{
    if ((self = [super init])) {
	integrator = [[CMTPRungeKuttaIntegrator alloc] initWithParticleSystem:self];	    // slower, more accurate
	//integrator = [[TPModifiedEulerIntegrator alloc] initWithParticleSystem:self];  // faster, less accurate
	
	particles = [[NSMutableArray alloc] init];
	springs = [[NSMutableArray alloc] init];
	attractions = [[NSMutableArray alloc] init];
	custom = [[NSMutableArray alloc] init];
	
	gravity = gravityVector;
	
	drag = dragValue;
    }
    return self;
}

- (void)dealloc
{
    [integrator release];
    [particles release];
    [springs release];
    [attractions release];
    [custom release];
    
    [super dealloc];
}

@end
