//
//  CMTPDClothTestViewController.m
//  CMTPDemo
//
//  Created by Chris Miles on 6/12/11.
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
#import <CoreMotion/CoreMotion.h>
#import "CMTPDClothTestViewController.h"
#import "CMTraerPhysics.h"
#import "CMGLESKTexture.h"
#import "CMGLESKProgram.h"
#import "CMGLESKUtil.h"
#import "CMGLESKMatrix3D.h"


static GLfloat *circle_vertices(unsigned int *count, float radius, unsigned int num_sections)
{
    GLfloat *vertices;
    unsigned int index = 0;
    
    *count = 2*(2+num_sections);
    vertices = malloc(sizeof(GLfloat) * *count);
    
    vertices[index++] = 0.0f;
    vertices[index++] = 0.0f;
    
    for (NSUInteger i=0; i<num_sections+1; i++) {
	vertices[index++] = radius * cosf(i * 2 * (float)M_PI / num_sections);
	vertices[index++] = radius * sinf(i * 2 * (float)M_PI / num_sections);
    }
    
    ZAssert(index <= *count, @"vertices array was too small");
    
    return vertices;
}

    
@interface CMTPDClothTestViewController () {
    BOOL animating;
    BOOL fullFrameRate;
    BOOL showGrid;
    BOOL showImage;
    
    float contentScale;
    float frameHeight, frameWidth;
    NSInteger animationFrameInterval;
    
    NSUInteger grabbedHandle;
    CGPoint handle1;
    CGPoint handle2;
    
    GLuint textureCoordAttrib;
    GLuint vertexAttrib;
    
    GLuint handle_vbo;
    unsigned int handleCount;
    
    GLfloat projectionMatrix[16];

    float gravityScale;
    NSUInteger gridSize;
    NSUInteger numGridVertices;
    GLfloat *texCoords;
    GLfloat *texVertices;
    GLfloat *gridVertices;
    
    CMMotionManager *motionManager;
    
    // FPS
    double	fps_prev_time;
    NSUInteger	fps_count;
    
    // Physics
    CMTPParticle *attractor;
    NSMutableArray *particles;
    BOOL physicsSetupCompleted;
    CMTPParticleSystem *s;
}

@property (strong, nonatomic) CADisplayLink *displayLink;
@property (strong, nonatomic) CMGLESKTexture *gridTexture;
@property (strong, nonatomic) CMGLESKProgram *shaderProgram;

- (void)startAnimation;
- (void)stopAnimation;

@end


@implementation CMTPDClothTestViewController

@synthesize displayLink;
@synthesize fullFrameRateLabel;
@synthesize accelerometerToggleView;
@synthesize fpsLabel;
@synthesize gridToggleView;
@synthesize imageToggleView;
@synthesize gridTexture;
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
}


#pragma mark - Control actions

- (IBAction)accelerometerToggleAction:(id)sender
{
    UISwitch *aSwitch = (UISwitch *)sender;
    
    if (aSwitch.on) {
        if ([motionManager isDeviceMotionAvailable]) {
            [motionManager startDeviceMotionUpdates];
        }
    }
    else {
        if ([motionManager isDeviceMotionActive]) {
            [motionManager stopDeviceMotionUpdates];
        }
    }
}

- (IBAction)gridToggleAction:(id)sender
{
    UISwitch *aSwitch = (UISwitch *)sender;
    showGrid = aSwitch.on;
    
    if (showGrid && !animating) {
	[self disableFullFrameRate];
	[self startAnimation];
    }
}

- (IBAction)imageToggleAction:(id)sender
{
    UISwitch *aSwitch = (UISwitch *)sender;
    showImage = aSwitch.on;
    
    if (showImage && !animating) {
	[self disableFullFrameRate];
	[self startAnimation];
    }
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
    
    /* *** Cloth Test **** */
    
    {
	CMTPParticle *p1 = [particles objectAtIndex:0];
	CMTPParticle *p2 = [particles objectAtIndex:gridSize-1];
	p1.position = CMTPVector3DMake(handle1.x, handle1.y, 0.0f);
	p2.position = CMTPVector3DMake(handle2.x, handle2.y, 0.0f);
    }

    if (motionManager.isDeviceMotionActive) {
        CMAcceleration gravity = motionManager.deviceMotion.gravity;
        CMTPVector3D gravityVector = CMTPVector3DMake((float)(gravity.x)*gravityScale, (float)(-gravity.y)*gravityScale, 0.0f);
        s.gravity = gravityVector;
    }
    
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
    
    glClearColor(0.2f, 0.2f, 0.2f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram(self.shaderProgram.program);
    ASSERT_GL_OK();
    
    int uniformMVP = [self.shaderProgram indexOfUniform:@"mvp"];

    
    if (showImage || showGrid) {
	/* Draw grab handles */
	Matrix3D translationMatrix, mvpMatrix;
	glUniform1i([self.shaderProgram indexOfUniform:@"colorOnly"], GL_TRUE);
	glUniform4f([self.shaderProgram indexOfUniform:@"color"], 0.8f, 0.8f, 0.8f, 1.0f);
	
	glBindBuffer(GL_ARRAY_BUFFER, handle_vbo);
	glEnableVertexAttribArray(vertexAttrib);
	glVertexAttribPointer(vertexAttrib, 2, GL_FLOAT, GL_FALSE, 0, 0);
	
	Matrix3DSetTranslation(translationMatrix, handle1.x*contentScale, handle1.y*contentScale, 0.0f);
	Matrix3DMultiply(projectionMatrix, translationMatrix, mvpMatrix);
	glUniformMatrix4fv(uniformMVP, 1, GL_FALSE, mvpMatrix);
	glDrawArrays(GL_TRIANGLE_FAN, 0, (GLsizei)handleCount);
	
	Matrix3DSetTranslation(translationMatrix, handle2.x*contentScale, handle2.y*contentScale, 0.0f);
	Matrix3DMultiply(projectionMatrix, translationMatrix, mvpMatrix);
	glUniformMatrix4fv(uniformMVP, 1, GL_FALSE, mvpMatrix);
	glDrawArrays(GL_TRIANGLE_FAN, 0, (GLsizei)handleCount);
	
	glDisableVertexAttribArray(vertexAttrib);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	ASSERT_GL_OK();
    }
    

    /* Reset mvp */
    glUniformMatrix4fv(uniformMVP, 1, GL_FALSE, projectionMatrix);
    ASSERT_GL_OK();
    
    
    if (showImage) {
        NSUInteger vIndex = 0;
        
        for (NSUInteger i=0; i<gridSize-1; i++) {
	    for (NSUInteger j=0; j<gridSize-1; j++) {
		CMTPParticle *pBotLeft =  [particles objectAtIndex:(gridSize-1-j-1)*gridSize+i];
		CMTPParticle *pBotRight = [particles objectAtIndex:(gridSize-1-j-1)*gridSize+i+1];
		CMTPParticle *pTopLeft =  [particles objectAtIndex:(gridSize-1-j)*gridSize+i];
		CMTPParticle *pTopRight = [particles objectAtIndex:(gridSize-1-j)*gridSize+i+1];
		
		texVertices[vIndex++] = pBotLeft.position.x * contentScale;
		texVertices[vIndex++] = pBotLeft.position.y * contentScale;
		
		texVertices[vIndex++] = pBotRight.position.x * contentScale;
		texVertices[vIndex++] = pBotRight.position.y * contentScale;
		
                texVertices[vIndex++] = pTopLeft.position.x * contentScale;
                texVertices[vIndex++] = pTopLeft.position.y * contentScale;
                
		texVertices[vIndex++] = pBotRight.position.x * contentScale;
		texVertices[vIndex++] = pBotRight.position.y * contentScale;
		
                texVertices[vIndex++] = pTopLeft.position.x * contentScale;
                texVertices[vIndex++] = pTopLeft.position.y * contentScale;
                
		texVertices[vIndex++] = pTopRight.position.x * contentScale;
		texVertices[vIndex++] = pTopRight.position.y * contentScale;
	    }
	}
        
        glUniform1i([self.shaderProgram indexOfUniform:@"colorOnly"], GL_FALSE);
        
        int stride = 0;
        
	glEnableVertexAttribArray(vertexAttrib); // vertex coords
	glVertexAttribPointer(vertexAttrib, 2, GL_FLOAT, GL_FALSE, stride, texVertices);
	glEnableVertexAttribArray(textureCoordAttrib); // texture coords
	glVertexAttribPointer(textureCoordAttrib, 2, GL_FLOAT, GL_FALSE, stride, texCoords);
	
	glActiveTexture(GL_TEXTURE0); 
	glBindTexture(GL_TEXTURE_2D, gridTexture.glTextureName);
	glUniform1i([self.shaderProgram indexOfUniform:@"sampler"], 0);
	
        glDrawArrays(GL_TRIANGLES, 0, vIndex/2);
        
	glDisableVertexAttribArray(textureCoordAttrib);
	glDisableVertexAttribArray(vertexAttrib);
    }
    
    if (showGrid) {
        NSUInteger vIndex = 0;
        
        glUniform1i([self.shaderProgram indexOfUniform:@"colorOnly"], GL_TRUE);
	glUniform4f([self.shaderProgram indexOfUniform:@"color"], 1.0f, 1.0f, 1.0f, 1.0f);
        
        int stride = 0;
        glEnableVertexAttribArray(vertexAttrib); // vertex coords
        ASSERT_GL_OK();
        
        NSUInteger count = 0;
        
        for (NSUInteger i=0; i<gridSize; i++) {
	    for (NSUInteger j=0; j<gridSize; j++) {
		if (j < gridSize-1) {
		    CMTPParticle *p1 = [particles objectAtIndex:count];
		    CMTPParticle *p2 = [particles objectAtIndex:count+1];
		    
		    gridVertices[vIndex++] = p1.position.x * contentScale;
		    gridVertices[vIndex++] = p1.position.y * contentScale;
		    gridVertices[vIndex++] = p2.position.x * contentScale;
		    gridVertices[vIndex++] = p2.position.y * contentScale;
		}
		count ++;
	    }
	}

        count = 0;
	
	for (NSUInteger i=0; i<gridSize-1; i++) {
	    for (NSUInteger j=0; j<gridSize; j++) {
		CMTPParticle *p1 = [particles objectAtIndex:count];
		CMTPParticle *p2 = [particles objectAtIndex:count+gridSize];
		
		gridVertices[vIndex++] = p1.position.x * contentScale;
		gridVertices[vIndex++] = p1.position.y * contentScale;
		gridVertices[vIndex++] = p2.position.x * contentScale;
		gridVertices[vIndex++] = p2.position.y * contentScale;
		
		count ++;
	    }
	}

        glVertexAttribPointer(vertexAttrib, 2, GL_FLOAT, GL_FALSE, stride, gridVertices);
        glDrawArrays(GL_LINES, 0, vIndex/2);
        
        glDisableVertexAttribArray(vertexAttrib);
        
    } /* showGrid */
    
    
    
    [glView.context presentRenderbuffer:GL_RENDERBUFFER];
    
    if (!showGrid && !showImage) {
	[self enableFullFrameRate];
    }
}


#pragma mark - Setup

- (void)setupPhysicsInFrame:(CGRect)frame
{
    /* AttractionGrid - creates a square grid */
    particles = [[NSMutableArray alloc] init];
    gravityScale = 1.0f * CGRectGetHeight(self.view.frame) / 320.0f;
    CMTPVector3D gravityVector = CMTPVector3DMake(0.0f, gravityScale, 0.0f);
    s = [[CMTPParticleSystem alloc] initWithGravityVector:gravityVector drag:0.06f];
    [s setIntegrator:CMTPParticleSystemIntegratorRungeKutta];
    
    NSUInteger sp = (NSUInteger)(CGRectGetWidth(frame) / gridSize / 3);
    NSUInteger sx = (NSUInteger)(CGRectGetWidth(frame)/2.0f - sp*gridSize/2.0f);
    NSUInteger sy = (NSUInteger)(CGRectGetHeight(frame) * 0.15f);

    // create grid of particles
    for (NSUInteger i=0; i<gridSize; i++) {
        for (NSUInteger j=0; j<gridSize; j++) {
            CMTPParticle *p = [s makeParticleWithMass:0.8f position:CMTPVector3DMake(sx+j*sp, sy+i*sp, 0.0f)];
            [particles addObject:p];
        }
    }
    
    // create springs
    for (NSUInteger i=0; i<gridSize; i++) { //horizontal
        for (NSUInteger j=0; j<gridSize-1; j++) {
            CMTPParticle *particleA = [particles objectAtIndex:(i*gridSize+j)];
            CMTPParticle *particleB = [particles objectAtIndex:(i*gridSize+j+1)];
            [s makeSpringBetweenParticleA:particleA particleB:particleB springConstant:1.0f damping:0.6f restLength:sp];
        }
    }
    for (NSUInteger i=0; i<gridSize-1; i++) { //vertical
        for (NSUInteger j=0; j<gridSize; j++) {
            CMTPParticle *particleA = [particles objectAtIndex:(i*gridSize+j)];
            CMTPParticle *particleB = [particles objectAtIndex:((i+1)*gridSize+j)];
            [s makeSpringBetweenParticleA:particleA particleB:particleB springConstant:1.0f damping:0.6f restLength:sp];
        }
    }
    
    CMTPParticle *particle = [particles objectAtIndex:0];
    [particle makeFixed];
    handle1.x = particle.position.x;
    handle1.y = particle.position.y;

    particle = [particles objectAtIndex:gridSize-1];
    [particle makeFixed];
    handle2.x = particle.position.x;
    handle2.y = particle.position.y;

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
    NSArray *attributeNames = [NSArray arrayWithObjects:@"position", @"textureCoord", nil];
    NSArray *uniformNames = [NSArray arrayWithObjects:@"color", @"colorOnly", @"mvp", @"sampler", nil];
    self.shaderProgram = [[[CMGLESKProgram alloc] init] autorelease];
    if (![self.shaderProgram loadProgramFromFilesVertexShader:@"ClothTestVertexShader.glsl" fragmentShader:@"ClothTestFragmentShader.glsl" attributeNames:attributeNames uniformNames:uniformNames error:&error]) {
        ALog(@"Shader program load failed: %@", error);
    }
    
    ASSERT_GL_OK();
    
    vertexAttrib = (GLuint)[self.shaderProgram indexOfAttribute:@"position"];
    textureCoordAttrib = (GLuint)[self.shaderProgram indexOfAttribute:@"textureCoord"];
    
    animating = NO;

    self.gridTexture = [CMGLESKTexture textureNamed:@"sandy_beach.jpg"];
    
    NSUInteger tIndex = 0;
    CGFloat imageGridSize = self.gridTexture.size.width / gridSize; // NOTE: assumes square image
    
    for (NSUInteger i=0; i<gridSize-1; i++) {
        for (NSUInteger j=0; j<gridSize-1; j++) {
            CGRect subRect = CGRectMake(imageGridSize*i, imageGridSize*(gridSize-j-1), imageGridSize, imageGridSize);
            CMGLESKTexCoord subTexRect = [gridTexture croppedTextureCoord:subRect];
            
            texCoords[tIndex++] = subTexRect.x1;
            texCoords[tIndex++] = subTexRect.y1;
            
            texCoords[tIndex++] = subTexRect.x2;
            texCoords[tIndex++] = subTexRect.y1;
            
            texCoords[tIndex++] = subTexRect.x1;
            texCoords[tIndex++] = subTexRect.y2;
            
            texCoords[tIndex++] = subTexRect.x2;
            texCoords[tIndex++] = subTexRect.y1;
            
            texCoords[tIndex++] = subTexRect.x1;
            texCoords[tIndex++] = subTexRect.y2;
            
            texCoords[tIndex++] = subTexRect.x2;
            texCoords[tIndex++] = subTexRect.y2;
        }
    }
    
    
    // Grab handle
    GLfloat *handleVertices = circle_vertices(&handleCount, 5.0f * contentScale, 10);
    
    glGenBuffers(1, &handle_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, handle_vbo);
    glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)(handleCount*sizeof(GL_FLOAT)), handleVertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0); // unbind
    ASSERT_GL_OK();
    
    free(handleVertices);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
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
    
    orthoMatrix(projectionMatrix, 0.0f, frameWidth, frameHeight, 0.0f, -1.0f, 1.0f); // inverted Y
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

- (void)moveHandle:(NSUInteger)handle toLocation:(CGPoint)location
{
    if (location.x < 0) location.x = 0;
    if (location.y < 0) location.y = 0;
    if (location.x >= frameWidth) location.x = frameWidth-1;
    if (location.y >= frameHeight) location.y = frameHeight-1;
    
    if (1 == handle) {
        handle1.x = location.x;
        handle1.y = location.y;
    }
    else if (2 == handle) {
        handle2.x = location.x;
        handle2.y = location.y;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    CGPoint diff1 = CGPointMake(location.x-handle1.x, location.y-handle1.y);
    CGPoint diff2 = CGPointMake(location.x-handle2.x, location.y-handle2.y);
    CGFloat distance1 = sqrtf(diff1.x*diff1.x + diff1.y*diff1.y);
    CGFloat distance2 = sqrtf(diff2.x*diff2.x + diff2.y*diff2.y);
    if (distance1 < 24.0f) {
        grabbedHandle = 1;
    }
    else if (distance2 < 24.0f) {
        grabbedHandle = 2;
    }
    
    if (grabbedHandle > 0) {
        [self moveHandle:grabbedHandle toLocation:location];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    [self moveHandle:grabbedHandle toLocation:location];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    grabbedHandle = 0;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    grabbedHandle = 0;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Cloth Test";
    
    NSMutableArray *toolbarItems = [NSMutableArray array];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithCustomView:self.gridToggleView] autorelease]];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithCustomView:self.fpsLabel] autorelease]];
    if (motionManager.isDeviceMotionAvailable) {
        [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
        [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithCustomView:self.accelerometerToggleView] autorelease]];
    }
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithCustomView:self.imageToggleView] autorelease]];
    
    self.toolbarItems = toolbarItems;
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    EAGLView *glView = (EAGLView *)self.view;
    contentScale = glView.contentScaleFactor;
    [self setupOpenGL];
}

- (void)viewDidUnload
{
    [self setFpsLabel:nil];
    [self setGridToggleView:nil];
    [self setImageToggleView:nil];
    [self setAccelerometerToggleView:nil];
    [self setFullFrameRateLabel:nil];
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


#pragma mark - Object lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        showGrid = YES;
        showImage = YES;
        gridSize = 8;
        numGridVertices = 2*(gridSize*gridSize + 2*gridSize*(gridSize-1));
        //DLog(@"gridSize=%d numGridVertices=%d", gridSize, numGridVertices);

        gridVertices = calloc(2*numGridVertices, sizeof(GLfloat));
        texCoords = calloc(6*2*(gridSize-1)*(gridSize-1), sizeof(GLfloat));
        texVertices = calloc(6*2*(gridSize-1)*(gridSize-1), sizeof(GLfloat));

        motionManager = [[CMMotionManager alloc] init];
        motionManager.deviceMotionUpdateInterval = 0.02; // 50 Hz
        
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [motionManager release];
    
    free(gridVertices);
    free(texCoords);
    free(texVertices);
    
    [accelerometerToggleView release];
    [attractor release];
    [displayLink release];
    [fpsLabel release];
    [fullFrameRateLabel release];
    [gridTexture release];
    [gridToggleView release];
    [imageToggleView release];
    [particles release];
    [s release];
    [shaderProgram release];
    
    [super dealloc];
}

@end
