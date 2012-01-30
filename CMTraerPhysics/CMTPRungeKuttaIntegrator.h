//
//  CMTPRungeKuttaIntegrator.h
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
#import "CMTPIntegrator.h"
#import "CMTPParticleSystem.h"

@interface CMVector3Dobj : NSObject {
    CMTPVector3D vector3D;
}
@property (nonatomic, assign) CMTPVector3D vector3D;
+ (CMVector3Dobj *)vector3Dobj;
@end;


@interface CMTPRungeKuttaIntegrator : CMTPIntegrator {
    CMTPParticleSystem *s;
    
    NSMutableArray *originalPositions;
    NSMutableArray *originalVelocities;
    NSMutableArray *k1Forces;
    NSMutableArray *k1Velocities;
    NSMutableArray *k2Forces;
    NSMutableArray *k2Velocities;
    NSMutableArray *k3Forces;
    NSMutableArray *k3Velocities;
    NSMutableArray *k4Forces;
    NSMutableArray *k4Velocities;
    
}

- (id)initWithParticleSystem:(CMTPParticleSystem *)aParticleSystem;

@end
