//
//  CMTPModifiedEulerIntegrator.m
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

#import "CMTPModifiedEulerIntegrator.h"


@implementation CMTPModifiedEulerIntegrator

- (void)step:(CMTPFloat)t
{
    NSArray *particles = s.particles;
    NSUInteger p_length = [particles count];
    
    [s clearForces];
    [s applyForces];
    
    CMTPFloat halftt = (t*t) * 0.5f;
    CMTPFloat one_over_t = 1/t;
    
    for (NSUInteger i = 0; i<p_length; i++) {
	
	CMTPParticle *p = [particles objectAtIndex:i];
	
	if (![p isFixed]) {
	    
	    CMTPFloat ax = p.force.x/p.mass;
	    CMTPFloat ay = p.force.y/p.mass;
	    CMTPFloat az = p.force.z/p.mass;
	    
	    CMTPVector3D vel_div_t = p.velocity;
	    vel_div_t = CMTPVector3DScaleBy(vel_div_t, one_over_t);
	    p.position = CMTPVector3DAdd(p.position, vel_div_t);
	    p.position = CMTPVector3DAdd(p.position, CMTPVector3DMake(ax*halftt, ay*halftt, az*halftt));
	    p.velocity = CMTPVector3DAdd(p.velocity, CMTPVector3DMake(ax*one_over_t, ay*one_over_t, az*one_over_t));
	}
    }
}

- (id)initWithParticleSystem:(CMTPParticleSystem *)aParticleSystem
{
    if ((self = [super init])) {
	s = aParticleSystem; // weak ref
    }
    return self;
}

- (void)dealloc
{
    s = nil;
    
    [super dealloc];
}

@end
