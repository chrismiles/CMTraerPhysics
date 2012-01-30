//
//  CMTPAttraction.h
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


#import <Foundation/Foundation.h>
#import "CMTPForce.h"
#import "CMTPParticle.h"

@interface CMTPAttraction : CMTPForce {
    CMTPParticle *particleA;
    CMTPParticle *particleB;
    
    CMTPFloat strength; //k
    
    CMTPFloat minDistance;
    CMTPFloat minDistanceSquared;
    
    BOOL on;
}

@property (nonatomic, assign) CMTPFloat minDistance;
@property (nonatomic, assign) CMTPFloat strength;

- (void)setMinDistance:(CMTPFloat)aMinDistance;
- (void)setParticleA:(CMTPParticle *)p;
- (void)setParticleB:(CMTPParticle *)p;
- (CMTPParticle *)getOneEnd;
- (CMTPParticle *)getTheOtherEnd;
- (id)initWithParticleA:(CMTPParticle *)aParticleA particleB:(CMTPParticle *)aParticleB strength:(CMTPFloat)aStrength minDistance:(CMTPFloat)aMinDistance;

@end
