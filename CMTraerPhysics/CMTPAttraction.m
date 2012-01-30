//
//  CMTPAttraction.m
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


#import "CMTPAttraction.h"


@implementation CMTPAttraction

@synthesize minDistance, strength;

- (void)setMinDistance:(CMTPFloat)aMinDistance
{
    minDistance = aMinDistance;
    minDistanceSquared = aMinDistance*aMinDistance;
}

- (void)turnOn
{
    on = YES;
}

- (void)turnOff
{
    on = NO;
}

- (BOOL)isOn
{
    return on;
}

- (BOOL)isOff
{
    return !on;
}

- (void)setParticleA:(CMTPParticle *)p
{
    [p retain];
    [particleA release];
    particleA = p;
}

- (void)setParticleB:(CMTPParticle *)p
{
    [p retain];
    [particleB release];
    particleB = p;
}

- (CMTPParticle *)getOneEnd
{
    return [[particleA retain] autorelease];
}

- (CMTPParticle *)getTheOtherEnd
{
    return [[particleB retain] autorelease];
}

- (void)apply
{
    if ( on && ( [particleA isFree] || [particleB isFree] ) ) {
	
	CMTPFloat a2bX = particleA.position.x - particleB.position.x;
	CMTPFloat a2bY = particleA.position.y - particleB.position.y;
	CMTPFloat a2bZ = particleA.position.z - particleB.position.z;
	
	CMTPFloat a2bDistanceSquared = a2bX*a2bX + a2bY*a2bY + a2bZ*a2bZ;
	
	if ( a2bDistanceSquared < minDistanceSquared ) a2bDistanceSquared = minDistanceSquared;
	
	CMTPFloat force = strength * particleA.mass * particleB.mass / a2bDistanceSquared;
	
	CMTPFloat length = sqrtf( a2bDistanceSquared );
	
	a2bX /= length;
	a2bY /= length;
	a2bZ /= length;
	
	a2bX *= force;
	a2bY *= force;
	a2bZ *= force;
	
	if ([particleA isFree]) particleA.force = CMTPVector3DAdd(particleA.force, CMTPVector3DMake(-a2bX, -a2bY, -a2bZ));
	if ([particleB isFree]) particleB.force = CMTPVector3DAdd(particleB.force, CMTPVector3DMake(a2bX, a2bY, a2bZ));
    }
}

- (id)initWithParticleA:(CMTPParticle *)aParticleA particleB:(CMTPParticle *)aParticleB strength:(CMTPFloat)aStrength minDistance:(CMTPFloat)aMinDistance
{
    if ((self = [super init])) {
	particleA = [aParticleA retain];
	particleB = [aParticleB retain];
	strength = aStrength;
	
	on = YES;
	
	minDistance = aMinDistance;
	minDistanceSquared = aMinDistance*aMinDistance;
    }
    return self;
}

- (void)dealloc
{
    [particleA release];
    [particleB release];
    
    [super dealloc];
}

@end
