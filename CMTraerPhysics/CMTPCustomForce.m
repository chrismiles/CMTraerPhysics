//
//  CMTPCustomForce.m
//  CMTraerPhysics
//
//  Created by Chris Miles 2011.
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

#import "CMTPCustomForce.h"

@implementation CMTPCustomForce

@synthesize particle;
@synthesize forceVector;

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

- (void)apply
{
    if (on && [particle isFree]) {
	particle.force = CMTPVector3DAdd(particle.force, self.forceVector);
    }
}

- (id)initWithParticle:(CMTPParticle *)aParticle forceVector:(CMTPVector3D)aForceVector
{
    if ((self = [super init])) {
	self.particle = aParticle;
	self.forceVector = aForceVector;
	
	on = YES;
    }
    return self;
}

@end
