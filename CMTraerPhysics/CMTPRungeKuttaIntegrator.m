//
//  CMTPRungeKuttaIntegrator.m
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

#import "CMTPRungeKuttaIntegrator.h"


@implementation CMVector3Dobj
@synthesize vector3D;
+ (CMVector3Dobj *)vector3Dobj
{
    return [[[CMVector3Dobj alloc] init] autorelease];
}
@end


@implementation CMTPRungeKuttaIntegrator

- (void)allocateParticles
{
    while ([s.particles count] > [originalPositions count]) {
	[originalPositions addObject:[CMVector3Dobj vector3Dobj]];
	[originalVelocities addObject:[CMVector3Dobj vector3Dobj]];
	[k1Forces addObject:[CMVector3Dobj vector3Dobj]];
	[k1Velocities addObject:[CMVector3Dobj vector3Dobj]];
	[k2Forces addObject:[CMVector3Dobj vector3Dobj]];
	[k2Velocities addObject:[CMVector3Dobj vector3Dobj]];
	[k3Forces addObject:[CMVector3Dobj vector3Dobj]];
	[k3Velocities addObject:[CMVector3Dobj vector3Dobj]];
	[k4Forces addObject:[CMVector3Dobj vector3Dobj]];
	[k4Velocities addObject:[CMVector3Dobj vector3Dobj]];
    }
}

- (void)step:(CMTPFloat)t
{
    [self allocateParticles];
    
    NSArray *particles = s.particles;
    NSUInteger i;
    NSUInteger p_length = [particles count];
    CMTPParticle *p;
    CMTPVector3D originalPosition;
    CMTPVector3D originalVelocity;
    
    CMTPVector3D k1Velocity;
    CMTPVector3D k2Velocity;
    CMTPVector3D k3Velocity;
    CMTPVector3D k4Velocity;
    
    CMTPVector3D k1Force;
    CMTPVector3D k2Force;
    CMTPVector3D k3Force;
    CMTPVector3D k4Force;
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // k1: save original, apply forces, result is k1
    // - - - - - - - - - - - - - - - - - - - - - - - - - - 
    for (i=0; i<p_length; i++) {
	
	p = [particles objectAtIndex:i];
	
	if (! [p isFixed]) {
	    CMVector3Dobj *v = [originalPositions objectAtIndex:i];
	    v.vector3D = p.position;
	    
	    v = [originalVelocities objectAtIndex:i];
	    v.vector3D = p.velocity;
	}
	
	p.force = CMTPVector3DMake(0, 0, 0);
	
    }
    
    [s applyForces];
    
    for (i=0; i<p_length; i++) {
	
	p = [particles objectAtIndex:i];
	
	if (! [p isFixed]) {
	    CMVector3Dobj *v = [k1Forces objectAtIndex:i];
	    v.vector3D = p.force;
	    
	    v = [k1Velocities objectAtIndex:i];
	    v.vector3D = p.velocity;
	}
	
	p.force = CMTPVector3DMake(0, 0, 0); //clear
	
    }
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - 	
    // k2: use k1, apply forces, result is k2
    // - - - - - - - - - - - - - - - - - - - - - - - - - - 
    for (i=0; i<p_length; i++) {
	
	p = [particles objectAtIndex:i];
	
	if (! [p isFixed]) {
	    originalPosition = [(CMVector3Dobj *)[originalPositions objectAtIndex:i] vector3D];
	    k1Velocity = [(CMVector3Dobj *)[k1Velocities objectAtIndex:i] vector3D];
	    
	    p.position = CMTPVector3DMake(originalPosition.x + k1Velocity.x * 0.5 * t,
                                          originalPosition.y + k1Velocity.y * 0.5 * t,
                                          originalPosition.z + k1Velocity.z * 0.5 * t);
	    
	    originalVelocity = [(CMVector3Dobj *)[originalVelocities objectAtIndex:i] vector3D];
	    k1Force = [(CMVector3Dobj *)[k1Forces objectAtIndex:i] vector3D];
	    
	    p.velocity = CMTPVector3DMake(originalVelocity.x + k1Force.x * 0.5 * t / p.mass,
                                          originalVelocity.y + k1Force.y * 0.5 * t / p.mass,
                                          originalVelocity.z + k1Force.z * 0.5 * t / p.mass);
	    
	    
	}
	
    }
    
    [s applyForces];
    
    for (i=0; i<p_length; i++) {
	
	p = [particles objectAtIndex:i];
	
	if (! [p isFixed]) {
	    CMVector3Dobj *v = [k2Forces objectAtIndex:i];
	    v.vector3D = p.force;
	    
	    v = [k2Velocities objectAtIndex:i];
	    v.vector3D = p.velocity;
	}
	
	p.force = CMTPVector3DMake(0, 0, 0); //clear
	
    }
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // k3: use k2, apply forces, result is k3
    // - - - - - - - - - - - - - - - - - - - - - - - - - - 
    
    for (i=0; i<p_length; i++) {
	
	p = [particles objectAtIndex:i];
	
	if (! [p isFixed]) {
	    originalPosition = [(CMVector3Dobj *)[originalPositions objectAtIndex:i] vector3D];
	    k2Velocity = [(CMVector3Dobj *)[k2Velocities objectAtIndex:i] vector3D];
	    
	    p.position = CMTPVector3DMake(originalPosition.x + k2Velocity.x * 0.5 * t,
                                          originalPosition.y + k2Velocity.y * 0.5 * t,
                                          originalPosition.z + k2Velocity.z * 0.5 * t);
	    
	    originalVelocity = [(CMVector3Dobj *)[originalVelocities objectAtIndex:i] vector3D];
	    k2Force = [(CMVector3Dobj *)[k2Forces objectAtIndex:i] vector3D];
	    
	    p.velocity = CMTPVector3DMake(originalVelocity.x + k2Force.x * 0.5 * t / p.mass,
                                          originalVelocity.y + k2Force.y * 0.5 * t / p.mass,
                                          originalVelocity.z + k2Force.z * 0.5 * t / p.mass);
	    
	}
	
    }
    
    [s applyForces];
    
    for (i=0; i<p_length; i++) {
	
	p = [particles objectAtIndex:i];
	
	if (! [p isFixed]) {
	    CMVector3Dobj *v = [k3Forces objectAtIndex:i];
	    v.vector3D = p.force;
	    
	    v = [k3Velocities objectAtIndex:i];
	    v.vector3D = p.velocity;
	}
	
	p.force = CMTPVector3DMake(0, 0, 0); //clear
	
    }
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // k4: use k3, apply forces, result is k4
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    for (i=0; i<p_length; i++) {
	
	p = [particles objectAtIndex:i];
	
	if (! [p isFixed]) {
	    originalPosition = [(CMVector3Dobj *)[originalPositions objectAtIndex:i] vector3D];
	    k3Velocity = [(CMVector3Dobj *)[k3Velocities objectAtIndex:i] vector3D];
	    
	    p.position = CMTPVector3DMake(originalPosition.x + k3Velocity.x * 0.5 * t,
                                          originalPosition.y + k3Velocity.y * 0.5 * t,
                                          originalPosition.z + k3Velocity.z * 0.5 * t);
	    
	    originalVelocity = [(CMVector3Dobj *)[originalVelocities objectAtIndex:i] vector3D];
	    k3Force = [(CMVector3Dobj *)[k3Forces objectAtIndex:i] vector3D];
	    
	    p.velocity = CMTPVector3DMake(originalVelocity.x + k3Force.x * 0.5 * t / p.mass,
                                          originalVelocity.y + k3Force.y * 0.5 * t / p.mass,
                                          originalVelocity.z + k3Force.z * 0.5 * t / p.mass);
	    
	}
	
    }
    
    [s applyForces];
    
    for (i=0; i<p_length; i++) {
	
	p = [particles objectAtIndex:i];
	
	if (! [p isFixed]) {
	    CMVector3Dobj *v = [k4Forces objectAtIndex:i];
	    v.vector3D = p.force;
	    
	    v = [k4Velocities objectAtIndex:i];
	    v.vector3D = p.velocity;
	}
	
	p.force = CMTPVector3DMake(0, 0, 0); //clear
	
    }
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // now update position and velocity 
    // based on intermediate forces
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    for (i=0; i< p_length; i++) {
	
	p = [particles objectAtIndex:i];
	p.age += t;
	
	if (! [p isFixed]) {
	    
	    // position
	    
	    originalPosition	= [(CMVector3Dobj *)[originalPositions objectAtIndex:i] vector3D];
	    k1Velocity			= [(CMVector3Dobj *)[k1Velocities objectAtIndex:i] vector3D];
	    k2Velocity			= [(CMVector3Dobj *)[k2Velocities objectAtIndex:i] vector3D];
	    k3Velocity			= [(CMVector3Dobj *)[k3Velocities objectAtIndex:i] vector3D];
	    k4Velocity			= [(CMVector3Dobj *)[k4Velocities objectAtIndex:i] vector3D];
	    
	    p.position = CMTPVector3DMake(originalPosition.x + t / 6*(k1Velocity.x + 2*k2Velocity.x + 2*k3Velocity.x + k4Velocity.x),
                                          originalPosition.y + t / 6*(k1Velocity.y + 2*k2Velocity.y + 2*k3Velocity.y + k4Velocity.y),
                                          originalPosition.z + t / 6*(k1Velocity.z + 2*k2Velocity.z + 2*k3Velocity.z + k4Velocity.z));
	    
	    // velocity
	    
	    originalVelocity	= [(CMVector3Dobj *)[originalVelocities objectAtIndex:i] vector3D];
	    k1Force				= [(CMVector3Dobj *)[k1Forces objectAtIndex:i] vector3D];
	    k2Force				= [(CMVector3Dobj *)[k2Forces objectAtIndex:i] vector3D];
	    k3Force				= [(CMVector3Dobj *)[k3Forces objectAtIndex:i] vector3D];
	    k4Force				= [(CMVector3Dobj *)[k4Forces objectAtIndex:i] vector3D];
	    
	    p.velocity = CMTPVector3DMake(originalVelocity.x + t / 6*p.mass * (k1Force.x + 2*k2Force.x + 2*k3Force.x + k4Force.x),
                                          originalVelocity.y + t / 6*p.mass * (k1Force.y + 2*k2Force.y + 2*k3Force.y + k4Force.y),
                                          originalVelocity.z + t / 6*p.mass * (k1Force.z + 2*k2Force.z + 2*k3Force.z + k4Force.z));
	    
	}
	
    }
    
}

- (id)initWithParticleSystem:(CMTPParticleSystem *)aParticleSystem
{
    if ((self = [super init])) {
	s = aParticleSystem; // weak ref
	
	originalPositions		= [[NSMutableArray alloc] init];
	originalVelocities		= [[NSMutableArray alloc] init];
	k1Forces				= [[NSMutableArray alloc] init];
	k1Velocities			= [[NSMutableArray alloc] init];
	k2Forces				= [[NSMutableArray alloc] init];
	k2Velocities			= [[NSMutableArray alloc] init];
	k3Forces				= [[NSMutableArray alloc] init];
	k3Velocities			= [[NSMutableArray alloc] init];
	k4Forces				= [[NSMutableArray alloc] init];
	k4Velocities			= [[NSMutableArray alloc] init];
	
    }
    return self;
}

- (void)dealloc
{
    s = nil;
    
    [originalPositions release];
    [originalVelocities release];
    [k1Forces release];
    [k1Velocities release];
    [k2Forces release];
    [k2Velocities release];
    [k3Forces release];
    [k3Velocities release];
    [k4Forces release];
    [k4Velocities release];
    
    [super dealloc];
}

@end
