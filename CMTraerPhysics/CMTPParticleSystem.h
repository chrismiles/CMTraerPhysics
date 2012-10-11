//
//  CMTPParticleSystem.h
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
#import "CMTPParticle.h"
#import "CMTPSpring.h"
#import "CMTPAttraction.h"
#import "CMTPCustomForce.h"

/* Enable DEBUG_PHYSICS_OBJECTS to log count of physics objects */
//#define DEBUG_PHYSICS_OBJECTS


typedef enum {
    CMTPParticleSystemIntegratorRungeKutta = 1,
    CMTPParticleSystemIntegratorModifiedEuler
} CMTPParticleSystemIntegrator;


@interface CMTPParticleSystem : NSObject {
    CMTPIntegrator *integrator;
    
    CMTPVector3D gravity;
    CMTPFloat drag;
    
    NSMutableArray *particles;
    NSMutableArray *springs;
    NSMutableArray *attractions;
    NSMutableArray *custom;
    
    BOOL hasDeadParticles;
    
#ifdef DEBUG_PHYSICS_OBJECTS
    CFTimeInterval debug_physics_prev_time;
#endif
}

@property (nonatomic, assign) CMTPFloat drag;
@property (nonatomic, assign) CMTPVector3D gravity;

@property (nonatomic, retain, readonly) NSMutableArray *particles;

- (void)setIntegrator:(CMTPParticleSystemIntegrator)anIntegrator;
- (void)tick:(CMTPFloat)t;
- (CMTPParticle *)makeParticleWithMass:(CMTPFloat)mass position:(CMTPVector3D)vector;
- (CMTPSpring *)makeSpringBetweenParticleA:(CMTPParticle *)particleA particleB:(CMTPParticle *)particleB springConstant:(CMTPFloat)springConstant damping:(CMTPFloat)damping restLength:(CMTPFloat)restLength;
- (CMTPAttraction *)makeAttractionBetweenParticleA:(CMTPParticle *)particleA particleB:(CMTPParticle *)particleB strength:(CMTPFloat)strength minDistance:(CMTPFloat)minDistance;
- (void)clear;
- (void)applyForces;
- (void)clearForces;
- (NSUInteger)numberOfParticles;
- (NSUInteger)numberOfSprings;
- (NSUInteger)numberOfAttractions;
- (CMTPParticle *)getParticleAtIndex:(NSUInteger)i;
- (CMTPSpring *)getSpringAtIndex:(NSUInteger)i;
- (CMTPAttraction *)getAttractionAtIndex:(NSUInteger)i;
- (void)addCustomForce:(CMTPForce *)f;
- (NSUInteger)numberOfCustomForces;
- (CMTPForce *)getCustomForceAtIndex:(NSUInteger)i;
- (void)removeCustomForceAtIndex:(NSUInteger)i;
- (BOOL)removeCustomForceByReference:(CMTPForce *)f;
- (void)removeSpringAtIndex:(NSUInteger)i;
- (BOOL)removeSpringByReference:(CMTPSpring *)s;
- (void)removeAttractionAtIndex:(NSUInteger)i;
- (BOOL)removeAttractionByReference:(CMTPAttraction *)a;
- (void)removeParticleAtIndex:(NSUInteger)i;
- (BOOL)removeParticleByReference:(CMTPParticle *)p;

- (id)initWithGravityVector:(CMTPVector3D)gravityVector drag:(CMTPFloat)dragValue;

@end
