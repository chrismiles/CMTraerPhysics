//
//  CMTPSpring.m
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

#import "CMTPSpring.h"

@implementation CMTPSpring

@synthesize damping,restLength,springConstant;

-(void)turnOn {
    on=YES;
}

-(void)turnOff {
    on=NO;
}

-(BOOL)isOn {
    return on;
}

-(BOOL)isOff {
    return !on;
}

-(CMTPFloat)currentLength {
    return CMTPVector3DDistance(particleA.position,particleB.position);
}

-(void)setParticleA:(CMTPParticle*)p {
    particleA=p;
}

-(void)setParticleB:(CMTPParticle*)p {
    particleB=p;
}

-(CMTPParticle*)getOneEnd {
    return particleA;
}

-(CMTPParticle*)getTheOtherEnd {
    return particleB;
}

-(void)apply {
    if (on&&([particleA isFree]||[particleB isFree])) {
        CMTPFloat a2bX=particleA.position.x-particleB.position.x;
        CMTPFloat a2bY=particleA.position.y-particleB.position.y;
        CMTPFloat a2bZ=particleA.position.z-particleB.position.z;

        CMTPFloat a2bDistance=sqrt(a2bX*a2bX+a2bY*a2bY+a2bZ*a2bZ);
        if (a2bDistance==0.0f) {
            a2bX=0;
            a2bY=0;
            a2bZ=0;
        } else {
            a2bX/=a2bDistance;
            a2bY/=a2bDistance;
            a2bZ/=a2bDistance;
        }
        CMTPFloat springForce=-(a2bDistance-restLength)*springConstant;

        CMTPFloat Va2bX=particleA.velocity.x-particleB.velocity.x;
        CMTPFloat Va2bY=particleA.velocity.y-particleB.velocity.y;
        CMTPFloat Va2bZ=particleA.velocity.z-particleB.velocity.z;

        CMTPFloat dampingForce=-damping*(a2bX*Va2bX+a2bY*Va2bY+a2bZ*Va2bZ);
        CMTPFloat r=springForce+dampingForce;

        a2bX*=r;
        a2bY*=r;
        a2bZ*=r;
        if ([particleA isFree]) {
            particleA.force=CMTPVector3DAdd(particleA.force,CMTPVector3DMake(a2bX,a2bY,a2bZ));
        }
        if ([particleB isFree]) {
            particleB.force=CMTPVector3DAdd(particleB.force,CMTPVector3DMake(-a2bX,-a2bY,-a2bZ));
        }
    }
}

-(id)initWithParticleA:(CMTPParticle*)aParticleA particleB:(CMTPParticle*)aParticleB springConstant:(CMTPFloat)aSpringConstant damping:(CMTPFloat)aDamping restLength:(CMTPFloat)aRestLength {
    if ((self=[super init])) {
        particleA=aParticleA;
        particleB=aParticleB;
        springConstant=aSpringConstant;
        damping=aDamping;
        restLength=aRestLength;

        on=YES;
    }
    return self;
}

@end

