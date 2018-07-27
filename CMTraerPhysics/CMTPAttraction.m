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

-(void)setMinDistance:(CMTPFloat)aMinDistance {
    _minDistance=aMinDistance;
    _minDistanceSquared=aMinDistance*aMinDistance;
}

-(void)turnOn {
    _on=YES;
}

-(void)turnOff {
    _on=NO;
}

-(BOOL)isOn {
    return _on;
}

-(BOOL)isOff {
    return !_on;
}

-(CMTPParticle*)getOneEnd {
    return _particleA;
}

-(CMTPParticle*)getTheOtherEnd {
    return _particleB;
}

-(void)apply {
    if (_on&&([_particleA isFree]||[_particleB isFree])) {
        CMTPFloat a2bX=_particleA.position.x-_particleB.position.x;
        CMTPFloat a2bY=_particleA.position.y-_particleB.position.y;
        CMTPFloat a2bZ=_particleA.position.z-_particleB.position.z;

        CMTPFloat a2bDistanceSquared=a2bX*a2bX+a2bY*a2bY+a2bZ*a2bZ;
        if (a2bDistanceSquared<_minDistanceSquared) {
            a2bDistanceSquared=_minDistanceSquared;
        }
        CMTPFloat force=_strength*_particleA.mass*_particleB.mass/a2bDistanceSquared;

        CMTPFloat length=sqrt(a2bDistanceSquared);

        a2bX/=length;
        a2bY/=length;
        a2bZ/=length;

        a2bX*=force;
        a2bY*=force;
        a2bZ*=force;
        if ([_particleA isFree]) {
            _particleA.force=CMTPVector3DAdd(_particleA.force,CMTPVector3DMake(-a2bX,-a2bY,-a2bZ));
        }
        if ([_particleB isFree]) {
            _particleB.force=CMTPVector3DAdd(_particleB.force,CMTPVector3DMake(a2bX,a2bY,a2bZ));
        }
    }
}

-(id)initWithParticleA:(CMTPParticle*)aParticleA particleB:(CMTPParticle*)aParticleB strength:(CMTPFloat)aStrength minDistance:(CMTPFloat)aMinDistance {
    if ((self=[super init])) {
        _particleA=aParticleA;
        _particleB=aParticleB;
        _strength=aStrength;

        _on=YES;

        _minDistance=aMinDistance;
        _minDistanceSquared=aMinDistance*aMinDistance;
    }
    return self;
}

@end

