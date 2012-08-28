//
//  CMTPParticle.m
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

#import "CMTPParticle.h"


@implementation CMTPParticle

@synthesize age, context, force, mass, position, velocity;

- (CMTPFloat)distanceToParticle:(CMTPParticle *)p
{
    return CMTPVector3DDistance(position, p.position);
}

- (void)makeFixed
{
    fixed = YES;
    velocity.x = 0; velocity.y = 0; velocity.z = 0;
}

- (void)makeFree
{
    fixed = NO;
}

- (BOOL)isFixed
{
    return fixed;
}

- (BOOL)isFree
{
    return !fixed;
}

- (void)setMass:(CMTPFloat)m
{
    mass = m;
}

- (void)reset
{
    age = 0;
    dead = NO;
    position.x	= 0; position.y	= 0; position.z	= 0;
    velocity.x	= 0; velocity.y	= 0; velocity.z	= 0;
    force.x	= 0; force.y	= 0; force.z	= 0;
    mass = 1;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p position=(%f, %f, %f)>", [self class], self, position.x, position.y, position.z];
}

- (id)initWithMass:(CMTPFloat)aMass position:(CMTPVector3D)aPosition
{
    if ((self = [super init])) {
	mass = aMass;
	position = aPosition;
	
	velocity = CMTPVector3DMake(0.0, 0.0, 0.0);
	force = CMTPVector3DMake(0.0, 0.0, 0.0);
	
	age = 0.0;
        
	dead = NO;
	fixed = NO;
    }
    return self;
}

- (void)dealloc
{
    [context release];
    
    [super dealloc];
}

@end
