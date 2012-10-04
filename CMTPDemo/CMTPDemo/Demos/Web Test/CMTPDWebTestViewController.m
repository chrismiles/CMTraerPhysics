//
//  CMTPDWebTestViewController.m
//  CMTPDemo
//
//  Created by Chris Miles on 30/12/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//
//  Based on traerAS3 example by Arnaud Icard, https://github.com/sqrtof5/traerAS3
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

#import <QuartzCore/QuartzCore.h>
#import "CMTPDWebTestViewController.h"
#import "CMTraerPhysics.h"
#import "CMGLESKProgram.h"
#import "CMGLESKUtil.h"


//#ifdef DEBUG
//#define ASSERT_GL_OK() do {\
//	GLenum glError = glGetError();\
//	if (glError != GL_NO_ERROR) {\
//	    ALog(@"glError: %d", glError);\
//	}} while (0)
//#else
//	#define ASSERT_GL_OK() do { } while (0)
//#endif


/* Return a random float between 0.0 and 1.0 */
static inline float randomClamp()
{
    return (float)(arc4random() % ((unsigned)RAND_MAX + 1)) / (float)((unsigned)RAND_MAX + 1);
}

static inline CGPoint CGPointFromPolar(CGFloat r, CGFloat theta)
{
    return CGPointMake(r * cosf(theta), r * sinf(theta));
}

static CGFloat CGPointDistance(CGPoint userPosition, CGPoint prevPosition)
{
    CGFloat dx = prevPosition.x - userPosition.x;
    CGFloat dy = prevPosition.y - userPosition.y;
    return sqrtf(dx*dx + dy*dy);
}

//static inline void orthoMatrix(GLfloat *matrix, float left, float right, float bottom, float top, float zNear, float zFar)
//{
//    matrix[ 0] = 2.0f / (right-left);
//    matrix[ 1] = 0.0f;
//    matrix[ 2] = 0.0f;
//    matrix[ 3] = 0.0f;
//    matrix[ 4] = 0.0f;
//    matrix[ 5] = 2.0f / (top-bottom);
//    matrix[ 6] = 0.0f;
//    matrix[ 7] = 0.0f;
//    matrix[ 8] = 0.0f;
//    matrix[ 9] = 0.0f;
//    matrix[10] = -2.0f / (zFar-zNear);
//    matrix[11] = 0.0f;
//    matrix[12] = -(right+left) / (right-left);
//    matrix[13] = -(top+bottom) / (top-bottom);
//    matrix[14] = -(zFar+zNear) / (zFar-zNear);
//    matrix[15] = 1.0f;
//}

/* Line intersection functions, borrowed from Cocos2D http://code.google.com/p/cocos2d-iphone/issues/detail?id=1193
 */
static BOOL ccpFastIntersect(CGPoint A, CGPoint B,
			     CGPoint C, CGPoint D,
			     float *S, float *T)
{
    // FAIL: Line undefined
    if ( (A.x==B.x && A.y==B.y) || (C.x==D.x && C.y==D.y) ) return NO;
    
    const float BAx = B.x - A.x;
    const float BAy = B.y - A.y;
    const float DCx = D.x - C.x;
    const float DCy = D.y - C.y;
    const float ACx = A.x - C.x;
    const float ACy = A.y - C.y;
    
    const float denom = DCy*BAx - DCx*BAy;
    
    *S = DCx*ACy - DCy*ACx;
    *T = BAx*ACy - BAy*ACx;
    
    if (denom == 0) {
        if (*S == 0 || *T == 0) { 
            // Lines incident
            return YES;   
        }
        // Lines parallel and not incident
        return NO;
    }
    
    *S = *S / denom;
    *T = *T / denom;
    
    // Point of intersection
    // CGPoint P;
    // P.x = A.x + *S * (B.x - A.x);
    // P.y = A.y + *S * (B.y - A.y);
    
    return YES;
}

static CGPoint ccpFastIntersectPoint(CGPoint A, CGPoint B,
				     CGPoint C, CGPoint D)
{
    float S=0.0f, T=0.0f;
    
    ccpFastIntersect(A, B, C, D, &S, &T);
    // Point of intersection
    CGPoint P;
    P.x = A.x + S * (B.x - A.x);
    P.y = A.y + S * (B.y - A.y);
    return P;
}


#pragma mark - CMTPDWebTestViewController

@interface CMTPDWebTestViewController () {
    BOOL animating;
    BOOL fullFrameRate;
    
    float contentScale;
    float frameHeight, frameWidth;
    NSInteger animationFrameInterval;
    
    GLuint vertexAttrib;
    GLfloat *webVertices;
    
    // FPS
    double	fps_prev_time;
    NSUInteger	fps_count;
    
    // Physics
    NSMutableArray *anchors;
    CMTPVector3D *anchors_copy;
    NSMutableArray *attractions;
    CMTPParticle *attractor;
    NSMutableArray *joints;
    NSMutableArray *particles;
    BOOL physicsSetupCompleted;
    CMTPParticleSystem *s;
    
    float attractionMinDistanceFactor;
    float attractionStrengthFactor;
    BOOL canModifyStructure;
    NSUInteger steps;
    NSUInteger numTurns;
    CGPoint q0, q1, q2, q3;
    CGPoint prevLocation, userLocation;
}

@property (strong, nonatomic) CADisplayLink *displayLink;
@property (strong, nonatomic) CMGLESKProgram *shaderProgram;

- (void)startAnimation;
- (void)stopAnimation;

@end


@implementation CMTPDWebTestViewController

@synthesize displayLink;
@synthesize fullFrameRateLabel;
@synthesize fullFrameRateToggleView;
@synthesize modifyStructureToggleView;
@synthesize fpsLabel;
@synthesize shaderProgram;


#pragma mark - Full Frame Rate management

- (void)enableFullFrameRate
{
    self.fullFrameRateLabel.center = CGPointMake(roundf(CGRectGetMidX(self.view.bounds)), roundf(CGRectGetMidY(self.view.bounds)));
    [self.view addSubview:self.fullFrameRateLabel];
    fullFrameRate = YES;
}

- (void)disableFullFrameRate
{
    [self.fullFrameRateLabel removeFromSuperview];
    fullFrameRate = NO;
    [self startAnimation];
}


#pragma mark - OpenGL rendering

- (void)drawFrame:(id)sender
{
    EAGLView *glView = (EAGLView *)self.view;
    [glView setFramebuffer];
    
    /* FPS */
    double curr_time = CACurrentMediaTime(); 
    if (curr_time - fps_prev_time >= 0.2) {
	double delta = (curr_time - fps_prev_time) / fps_count;
	fpsLabel.text = [NSString stringWithFormat:@"%0.0f fps", 1.0/delta];
	fps_prev_time = curr_time;
	fps_count = 1;
    }
    else {
	fps_count++;
    }
    
    /* *** Web Test **** */
    
    attractor.position = CMTPVector3DMake(userLocation.x, userLocation.y, 0.0f);
    
    
    [s tick:1];
    
    if (fullFrameRate) {
	// Simulate at full frame rate; skip rendering as there's nothing to draw
	if (animating) {
	    [self stopAnimation];
	}
	[self performSelector:@selector(drawFrame:) withObject:nil afterDelay:0.0];
	return;
    }
    
    
    /* GL rendering */
    
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram(self.shaderProgram.program);
    ASSERT_GL_OK();
    
    GLfloat projectionMatrix[16];
    orthoMatrix(projectionMatrix, 0.0f, frameWidth, frameHeight, 0.0f, -1.0f, 1.0f); // inverted Y
    int uniformMVP = [self.shaderProgram indexOfUniform:@"mvp"];
    glUniformMatrix4fv(uniformMVP, 1, GL_FALSE, projectionMatrix);
    ASSERT_GL_OK();
    
    glUniform4f([self.shaderProgram indexOfUniform:@"color"], 1.0f, 1.0f, 1.0f, 1.0f);
    ASSERT_GL_OK();

    NSUInteger vIndex = 0;
    int stride = 0;
    glEnableVertexAttribArray(vertexAttrib); // vertex coords
    ASSERT_GL_OK();
    
    // draw spiral
    for (NSUInteger i = 2; i < [particles count]; i++) {
	CMTPParticle *p0 = [particles objectAtIndex:i-1];
	CMTPParticle *p1 = [particles objectAtIndex:i];
	
	webVertices[vIndex++] = p0.position.x * contentScale;
	webVertices[vIndex++] = p0.position.y * contentScale;
	webVertices[vIndex++] = p1.position.x * contentScale;
	webVertices[vIndex++] = p1.position.y * contentScale;
    }
    
    // draw armature
    for (NSUInteger i = 1; i <= steps; i++) {
	CMTPParticle *p0 = [particles objectAtIndex:i];
	CMTPVector3D pos0 = p0.position;
	for (NSUInteger j = 0; j <= numTurns; j++) {
	    NSUInteger index = i + (j * steps);
	    if (index < [particles count]) {
		CMTPParticle *p1 = [particles objectAtIndex:index];
		webVertices[vIndex++] = pos0.x * contentScale;
		webVertices[vIndex++] = pos0.y * contentScale;
		webVertices[vIndex++] = p1.position.x * contentScale;
		webVertices[vIndex++] = p1.position.y * contentScale;
		
		pos0 = p1.position;
	    }
	}
    }
    
    // draw joints to frame
    for (NSUInteger i = 0; i <= steps; i++) {
	NSUInteger p0_index = i + (NSUInteger)((numTurns-1) * steps);
	if (p0_index < [particles count]) {
	    CMTPParticle *p0 = [particles objectAtIndex:p0_index];
	    CMTPParticle *p1 = [joints objectAtIndex:i];
	    webVertices[vIndex++] = p0.position.x * contentScale;
	    webVertices[vIndex++] = p0.position.y * contentScale;
	    webVertices[vIndex++] = p1.position.x * contentScale;
	    webVertices[vIndex++] = p1.position.y * contentScale;
	}
    }
    
    // set attraction based on touch motion, and modify structure if option enabled
    if (prevLocation.x >= 0.0f) {
	float user_d = CGPointDistance(userLocation, prevLocation);
	
	for (NSUInteger i = 0; i < [attractions count]; i++) {
	    CMTPAttraction *a = [attractions objectAtIndex:i];
	    [a setMinDistance:user_d * attractionMinDistanceFactor];
	    [a setStrength:(attractionStrengthFactor * (user_d*user_d))];
	    
	    if (canModifyStructure && user_d > 4) {
		CMTPParticle *p = [particles objectAtIndex:i];
		CMTPParticle *anchor = [anchors objectAtIndex:i];
		CMTPVector3D newPosition = CMTPVector3DMake(anchor.position.x + (p.position.x - anchor.position.x)*0.2f, anchor.position.y + (p.position.y - anchor.position.y)*0.2f, 0.0f);
		anchor.position = newPosition;
	    }
	}
    }
    
    prevLocation = userLocation;

    glVertexAttribPointer(vertexAttrib, 2, GL_FLOAT, GL_FALSE, stride, webVertices);
    glDrawArrays(GL_LINES, 0, vIndex/2);
    
    glDisableVertexAttribArray(vertexAttrib);
    
    [glView.context presentRenderbuffer:GL_RENDERBUFFER];
}


#pragma mark - Setup

- (void)setupPhysicsInFrame:(CGRect)frame
{
    steps = 20;
    numTurns = 10;
    
    float ox = CGRectGetMidX(frame);
    float oy = CGRectGetMidY(frame);
    float a = 6.0f;
    float b = 1.1f;
    
    anchors = [[NSMutableArray alloc] init];
    anchors_copy = calloc(numTurns * steps, sizeof(CMTPVector3D));
    attractions = [[NSMutableArray alloc] init];
    joints = [[NSMutableArray alloc] init];
    particles = [[NSMutableArray alloc] init];
    
    // modifying an archimedean spiral to get a spider web-like structure
    
    //points defining the frame the structure is attached to
    q0 = CGPointMake(CGRectGetMinX(self.view.bounds), CGRectGetMinY(self.view.bounds));
    q1 = CGPointMake(CGRectGetMaxX(self.view.bounds), CGRectGetMinY(self.view.bounds));
    q2 = CGPointMake(CGRectGetMaxX(self.view.bounds), CGRectGetMaxY(self.view.bounds));
    q3 = CGPointMake(CGRectGetMinX(self.view.bounds), CGRectGetMaxY(self.view.bounds));

    float screenScale = 1.0f * CGRectGetHeight(self.view.frame) / 320.0f;
    
    CMTPVector3D gravityVector = CMTPVector3DMake(0.0f, 0.0f, 0.0f);
    s = [[CMTPParticleSystem alloc] initWithGravityVector:gravityVector drag:0.42f];
    
    b *= screenScale;	// scale for display size
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
	// iPad
	attractionMinDistanceFactor = 1.3f;
	attractionStrengthFactor = 150.0f;
    }
    else {
	// iPhone
	attractionMinDistanceFactor = 1.1f;
	attractionStrengthFactor = 50.0f;
    }
    
    attractor = [[s makeParticleWithMass:1.0f position:CMTPVector3DMake(ox, oy, 0.0f)] retain];
    [attractor makeFixed];


    // generate main archimedean spiral, from polar equation r = a + b*theta
    // create two sets of particles, one set fixed, one set free
    // http://en.wikipedia.org/wiki/Archimedean_spiral
    
    NSUInteger anchorIndex = 0;
    
    for (NSUInteger i = 1; i <= numTurns; i++) {
	for (NSUInteger j = 0; j < steps; j++) {
	    float rand = 1 + randomClamp() * .008f; //add some small irregularities
	    
	    float theta = (j * (((float)M_PI * 2) / steps)) + (i * (float)M_PI * 2) + (float)M_PI/2; // add 90 deg so the orientation of web is correct (starts at top)
	    float r = a + (b * theta) * rand;
	    // use theta*-1 as spiders create their final web outwards, turning clockwise 
	    CGPoint pos = CGPointFromPolar(r, -theta);
	    
	    CMTPParticle *pfree = [s makeParticleWithMass:0.8f position:CMTPVector3DMake(ox + pos.x * rand, oy + pos.y * rand, 0)];
	    CMTPParticle *pfixed = [s makeParticleWithMass:0.8f position:CMTPVector3DMake(ox + pos.x * rand, oy + pos.y * rand, 0)];
	    [pfixed makeFixed];
	    
	    // Attraction strength & minDistance will be overriden based on user input
	    CMTPAttraction *attr = [s makeAttractionBetweenParticleA:attractor particleB:pfree strength:1.0f minDistance:1.0f];
	    [attractions addObject:attr];
	    [particles addObject:pfree];
	    [anchors addObject:pfixed];
	    
	    if (i == 1) {
		pfree.position = CMTPVector3DMake(ox, oy, 0.0f);
		pfixed.position = pfree.position;
	    }
	    
	    anchors_copy[anchorIndex++] = CMTPVector3DMake(pfixed.position.x, pfixed.position.y, pfixed.position.z);
	    
	    [s makeSpringBetweenParticleA:pfree particleB:pfixed springConstant:0.42f damping:0.0f restLength:randomClamp()*1.01f];
	}
    }
    
    // at this point the pattern we have is too regular
    // we need to change that a bit
    
    // NOTE: the mix of vector math + "custom" calc is horrible, to rewrite using Vector3D methods only
    
    for (NSUInteger i = 0; i < steps-2; i++) {
	NSUInteger seed_index = i + (NSUInteger)((numTurns-1) * steps);
	
	if (seed_index < [particles count]) {
	    
	    CMTPParticle *p0 = [particles objectAtIndex:seed_index];
	    CMTPVector3D seed_pos = p0.position;
	    
	    CMTPParticle *p1 = [particles objectAtIndex:i + (NSUInteger)((numTurns-2) * steps)];
	    CMTPVector3D n_pt_pos = p1.position;
	    
	    float mod_scale = randomClamp() * -4.0f;
	    CMTPVector3D mod_v = CMTPVector3DMake((n_pt_pos.x - seed_pos.x)*mod_scale, (n_pt_pos.y - seed_pos.y)*mod_scale, 0.0f);
	    
	    CMTPVector3D next_seed_pos = CMTPVector3DMake(seed_pos.x + mod_v.x, seed_pos.y + mod_v.y, 0.0f);
	    
	    //clip to frame with an offset
	    float _sp = 25;
	    if (next_seed_pos.x < q0.x + _sp) next_seed_pos.x = q0.x + _sp;
	    if (next_seed_pos.y < q0.y + _sp) next_seed_pos.y = q0.y + _sp;
	    if (next_seed_pos.x > q1.x - _sp) next_seed_pos.x = q1.x - _sp;
	    if (next_seed_pos.y > q2.y - _sp) next_seed_pos.y = q2.y - _sp;
	    
	    float dx = next_seed_pos.x - seed_pos.x;
	    float dy = next_seed_pos.y - seed_pos.y;
	    float d = sqrtf(dx*dx + dy*dy);
	    
	    for (NSUInteger j=0; j<[particles count]; j++) {
		CMTPParticle *pj = [particles objectAtIndex:j];
		float _dx = next_seed_pos.x - pj.position.x;
		float _dy = next_seed_pos.y - pj.position.y;
		float _d = sqrtf(_dx*_dx + _dy*_dy);
		if (d != 0) {
		    float r = (d/_d); // we could use just that...
		    //r = r*r; // ...but here we attenuate a bit the displacement of the influenced particles
		    //r = r*r*r; // ...or this would give an even more spiky look
		    
		    float p_pos_x = pj.position.x + dx*r;
		    float p_pos_y = pj.position.y + dy*r;
		    
		    pj.position = CMTPVector3DMake(p_pos_x, p_pos_y, 0.0f);
		    CMTPParticle *anchor = [anchors objectAtIndex:j];
		    anchor.position = pj.position;
		    anchors_copy[j] = pj.position;
		}
	    }
	    
	    p0.position = next_seed_pos;
	    CMTPParticle *anchor = [anchors objectAtIndex:seed_index];
	    anchor.position = next_seed_pos;
	    anchors_copy[seed_index] = next_seed_pos;
	}
    }
    
    // generate spring-dampers keeping the structure together
    
    // main spiral
    for (NSUInteger i = 2; i < [particles count]; i++) {
	CMTPParticle *p0 = [particles objectAtIndex:i];
	CMTPParticle *p1 = [particles objectAtIndex:i-1];
	float dx = p0.position.x - p1.position.x;
	float dy = p0.position.y - p1.position.y;
	float d = sqrtf(dx*dx + dy*dy);
	[s makeSpringBetweenParticleA:p1 particleB:p0 springConstant:0.03f damping:0.61f restLength:d];
    }
    
    // joints to frame: create necessary fixed particles and connect
    // we'll need to figure out were the armature should intersect the frame

    for (NSUInteger i = 0; i <= steps; i++) {
	NSUInteger p0_index = i + (numTurns-1) * steps;
	
	if (p0_index < [particles count]) {
	    NSUInteger p1_index = i + (numTurns-2) * steps;
	    
	    CMTPParticle *particle0 = [particles objectAtIndex:p0_index];
	    CMTPParticle *particle1 = [particles objectAtIndex:p1_index];
	    CGPoint p0 = CGPointMake(particle0.position.x, particle0.position.y);
	    CGPoint p1 = CGPointMake(particle1.position.x, particle1.position.y);
	    
	    CGPoint intersect_top = ccpFastIntersectPoint(p0, p1, q0, q1);
	    CGPoint intersect_right = ccpFastIntersectPoint(p0, p1, q1, q2);
	    CGPoint intersect_bottom = ccpFastIntersectPoint(p0, p1, q3, q2);
	    CGPoint intersect_left = ccpFastIntersectPoint(p0, p1, q0, q3);
	    
	    // what's the closest intersection point to p0?
	    CGPoint top_bottom = (CGPointDistance(p0, intersect_top) < CGPointDistance(p0, intersect_bottom))? intersect_top : intersect_bottom;
	    CGPoint left_right = (CGPointDistance(p0, intersect_left) < CGPointDistance(p0, intersect_right))? intersect_left : intersect_right;
	    CGPoint closest = (CGPointDistance(p0, top_bottom) < CGPointDistance(p0, left_right))? top_bottom : left_right;
	    
	    CMTPParticle *p = [s makeParticleWithMass:0.8f position:CMTPVector3DMake(closest.x, closest.y, 0.0f)];
	    [p makeFixed];
	    
	    [joints addObject:p];
	    
	    CGFloat d = CGPointDistance(closest, p0); //make the rest length equals to the distance between these 2 points
	    [s makeSpringBetweenParticleA:p particleB:particle0 springConstant:0.05f damping:0.01f restLength:d]; //make these a bit different to stretch the structure
	}
    }
    
    prevLocation = CGPointMake(-1.0f, -1.0f);
}

- (void)setupOpenGL
{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!context) {
        ALog(@"Failed to create ES context");
    }
    else if (![EAGLContext setCurrentContext:context]) {
        ALog(@"Failed to set ES context current");
    }
    ASSERT_GL_OK();
    
    EAGLView *glView = (EAGLView *)self.view;
    [glView setContext:context];
    [context release];
    [glView setFramebuffer];
    
    NSError *error = nil;
    NSArray *attributeNames = [NSArray arrayWithObjects:@"position", nil];
    NSArray *uniformNames = [NSArray arrayWithObjects:@"color", @"mvp", nil];
    self.shaderProgram = [[[CMGLESKProgram alloc] init] autorelease];
    if (![self.shaderProgram loadProgramFromFilesVertexShader:@"WebTestVertexShader.glsl" fragmentShader:@"WebTestFragmentShader.glsl" attributeNames:attributeNames uniformNames:uniformNames error:&error]) {
        ALog(@"Shader program load failed: %@", error);
    }
    
    ASSERT_GL_OK();
    
    vertexAttrib = (GLuint)[self.shaderProgram indexOfAttribute:@"position"];
    
    animating = NO;
}


#pragma mark - Animation management

- (void)startAnimation
{
    if (!animating) {
        self.displayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(drawFrame:)];
        [self.displayLink setFrameInterval:animationFrameInterval];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        animating = YES;
    }
}

- (void)stopAnimation
{
    if (animating) {
        [self.displayLink invalidate];
        self.displayLink = nil;
	
        animating = NO;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(drawFrame:) object:nil];
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    /*
     Frame interval defines how many display frames must pass between each time the display link fires.
     The display link will only fire 30 times a second when the frame internal is two on a display that refreshes 60 times a second. The default frame interval setting of one will fire 60 times a second when the display refreshes at 60 times a second. A frame interval setting of less than one results in undefined behavior.
     */
    if (frameInterval >= 1) {
        animationFrameInterval = frameInterval;
        
        if (animating) {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}


#pragma mark - EAGLViewDelegate methods

- (void)eaglView:(EAGLView *)eaglView framebufferCreatedWithSize:(CGSize)framebufferSize
{
    frameWidth = framebufferSize.width;
    frameHeight = framebufferSize.height;
    contentScale = eaglView.contentScaleFactor;
}


#pragma mark - UIControl actions

- (IBAction)fullFrameRateAction:(id)sender
{
    UISwitch *sw = (UISwitch *)sender;
    if (sw.on) {
	[self enableFullFrameRate];
    }
    else {
	[self disableFullFrameRate];
    }
}

- (IBAction)modifyStructureAction:(id)sender
{
    UISwitch *sw = (UISwitch *)sender;
    canModifyStructure = sw.on;
}


#pragma mark - Application state changes

- (void)applicationWillResignActiveNotification:(NSNotification *)notification
{
    [self stopAnimation];
}

- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification
{
    [self startAnimation];
}


#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    prevLocation = CGPointMake(-1.0f, -1.0f);
    userLocation = [touch locationInView:self.view];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    userLocation = [touch locationInView:self.view];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Web Test";
    
    NSMutableArray *toolbarItems = [NSMutableArray array];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithCustomView:self.fullFrameRateToggleView] autorelease]];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithCustomView:self.fpsLabel] autorelease]];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithCustomView:self.modifyStructureToggleView] autorelease]];
    
    self.toolbarItems = toolbarItems;
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    EAGLView *glView = (EAGLView *)self.view;
    contentScale = glView.contentScaleFactor;
    [self setupOpenGL];
}

- (void)viewDidUnload
{
    [self setFpsLabel:nil];
    [self setFullFrameRateLabel:nil];
    [self setFullFrameRateToggleView:nil];
    [self setModifyStructureToggleView:nil];
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!physicsSetupCompleted) {
        [self setupPhysicsInFrame:self.view.frame];
        physicsSetupCompleted = YES;
    }
    
    fps_prev_time = CACurrentMediaTime();
    [self startAnimation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopAnimation];
    
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - Object lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSUInteger numWebVertices = 1908;
	
        webVertices = calloc(2*numWebVertices, sizeof(GLfloat));
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    free(webVertices);
    free(anchors_copy);
    
    [anchors release];
    [attractor release];
    [attractions release];
    [displayLink release];
    [fpsLabel release];
    [fullFrameRateLabel release];
    [fullFrameRateToggleView release];
    [joints release];
    [modifyStructureToggleView release];
    [particles release];
    [s release];
    [shaderProgram release];
    
    [super dealloc];
}

@end
