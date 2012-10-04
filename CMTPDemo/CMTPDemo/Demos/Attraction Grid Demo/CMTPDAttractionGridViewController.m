//
//  CMTPDAttractionGridViewController.m
//  CMTPDemo
//
//  Created by Chris Miles on 14/11/11.
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
#import "CMTPDAttractionGridViewController.h"
#import "CMTraerPhysics.h"
#import "CMGLESKTexture.h"
#import "CMGLESKProgram.h"
#import "CMGLESKUtil.h"

#define GRID_SIZE 32
#define NUM_GRID_VERTICES (2*(GRID_SIZE*GRID_SIZE + 2*GRID_SIZE*(GRID_SIZE-1)))


#pragma mark - CMTPDAttractionGridViewController

@interface CMTPDAttractionGridViewController () {
    BOOL animating;
    BOOL fullFrameRate;
    BOOL showGrid;
    BOOL showImage;
    
    float contentScale;
    float frameHeight, frameWidth;
    NSInteger animationFrameInterval;
    
    GLfloat mouseX;
    GLfloat mouseY;

    GLuint colorAttrib;
    GLuint textureCoordAttrib;
    GLuint vertexAttrib;

    GLfloat texCoords[6*2*(GRID_SIZE-1)*(GRID_SIZE-1)];

    // FPS
    double	fps_prev_time;
    NSUInteger	fps_count;

    // Physics
    CMTPParticle *attractor;
    NSMutableArray *particles_fixed;
    NSMutableArray *particles_free;
    BOOL physicsSetupCompleted;
    CMTPParticleSystem *s;
}

@property (strong, nonatomic) CADisplayLink *displayLink;
@property (strong, nonatomic) CMGLESKTexture *gridTexture;
@property (strong, nonatomic) CMGLESKProgram *shaderProgram;

- (void)startAnimation;
- (void)stopAnimation;

@end


@implementation CMTPDAttractionGridViewController

@synthesize displayLink;
@synthesize fpsLabel;
@synthesize fullFrameRateLabel;
@synthesize glView;
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
    [self.glView setFramebuffer];

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

    /* *** AttractionGrid **** */
    
    [s tick:1];

    attractor.position = CMTPVector3DMake(mouseX, mouseY, 0);

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

    GLfloat projectionMatrix[16];
    orthoMatrix(projectionMatrix, 0.0f, frameWidth, 0.0f, frameHeight, -1.0f, 1.0f);
    int uniformMVP = [self.shaderProgram indexOfUniform:@"mvp"];
    glUniformMatrix4fv(uniformMVP, 1, GL_FALSE, projectionMatrix);
    ASSERT_GL_OK();
    
    
    if (showImage) {
        GLfloat vertices[6*2*(GRID_SIZE-1)*(GRID_SIZE-1)];

        NSUInteger vIndex = 0;
        
        for (NSUInteger i=0; i<GRID_SIZE-1; i++) {
	    for (NSUInteger j=0; j<GRID_SIZE-1; j++) {
		CMTPParticle *pBotLeft =  [particles_free objectAtIndex:(GRID_SIZE-1-j-1)*GRID_SIZE+i];
		CMTPParticle *pBotRight = [particles_free objectAtIndex:(GRID_SIZE-1-j-1)*GRID_SIZE+i+1];
		CMTPParticle *pTopLeft =  [particles_free objectAtIndex:(GRID_SIZE-1-j)*GRID_SIZE+i];
		CMTPParticle *pTopRight = [particles_free objectAtIndex:(GRID_SIZE-1-j)*GRID_SIZE+i+1];
		
		vertices[vIndex++] = pBotLeft.position.x * contentScale;
		vertices[vIndex++] = pBotLeft.position.y * contentScale;
		
		vertices[vIndex++] = pBotRight.position.x * contentScale;
		vertices[vIndex++] = pBotRight.position.y * contentScale;
		
                vertices[vIndex++] = pTopLeft.position.x * contentScale;
                vertices[vIndex++] = pTopLeft.position.y * contentScale;
                
		vertices[vIndex++] = pBotRight.position.x * contentScale;
		vertices[vIndex++] = pBotRight.position.y * contentScale;
		
                vertices[vIndex++] = pTopLeft.position.x * contentScale;
                vertices[vIndex++] = pTopLeft.position.y * contentScale;
                
		vertices[vIndex++] = pTopRight.position.x * contentScale;
		vertices[vIndex++] = pTopRight.position.y * contentScale;
	    }
	}

        glUniform1i([self.shaderProgram indexOfUniform:@"colorOnly"], GL_FALSE);
        
        int stride = 0;
        
	glEnableVertexAttribArray(vertexAttrib); // vertex coords
	glVertexAttribPointer(vertexAttrib, 2, GL_FLOAT, GL_FALSE, stride, vertices);
	glEnableVertexAttribArray(textureCoordAttrib); // texture coords
	glVertexAttribPointer(textureCoordAttrib, 2, GL_FLOAT, GL_FALSE, stride, texCoords);
	
	glActiveTexture(GL_TEXTURE0); 
	glBindTexture(GL_TEXTURE_2D, gridTexture.glTextureName);
	glUniform1i([self.shaderProgram indexOfUniform:@"sampler"], 0);
	
	//glDrawArrays(GL_TRIANGLE_STRIP, 0, vIndex/2);
        glDrawArrays(GL_TRIANGLES, 0, vIndex/2);
        
	glDisableVertexAttribArray(textureCoordAttrib);
	glDisableVertexAttribArray(vertexAttrib);
    }
    
    if (showGrid) {
	GLfloat vertices[2*NUM_GRID_VERTICES];
        GLubyte colors[4*NUM_GRID_VERTICES];
        NSUInteger vIndex = 0;
        NSUInteger cIndex = 0;
        
        glUniform1i([self.shaderProgram indexOfUniform:@"colorOnly"], GL_TRUE);
        
        int stride = 0;
        glEnableVertexAttribArray(vertexAttrib); // vertex coords
        glEnableVertexAttribArray(colorAttrib);  // colors
        ASSERT_GL_OK();

	NSUInteger pfixed_count = [particles_fixed count];
	for (NSUInteger i = 0; i<pfixed_count; i++) {
	    CMTPParticle *pFixed = [particles_fixed objectAtIndex:i];
	    CMTPParticle *pFree = [particles_free objectAtIndex:i];
	    
	    vertices[vIndex++] = pFixed.position.x * contentScale;
	    vertices[vIndex++] = pFixed.position.y * contentScale;
	    vertices[vIndex++] = pFree.position.x * contentScale;
	    vertices[vIndex++] = pFree.position.y * contentScale;
            
            colors[cIndex++] = 255;
            colors[cIndex++] = 0;
            colors[cIndex++] = 0;
            colors[cIndex++] = 255;
	    
            colors[cIndex++] = 255;
            colors[cIndex++] = 0;
            colors[cIndex++] = 0;
            colors[cIndex++] = 255;
	}
	
	NSUInteger count = 0;
	
	for (NSUInteger i=0; i<GRID_SIZE; i++) {
	    for (NSUInteger j=0; j<GRID_SIZE; j++) {
		if (j <GRID_SIZE-1) {
		    CMTPParticle *pFree = [particles_free objectAtIndex:count];
		    CMTPParticle *pFree1 = [particles_free objectAtIndex:count+1];
		    
		    vertices[vIndex++] = pFree.position.x * contentScale;
		    vertices[vIndex++] = pFree.position.y * contentScale;
		    vertices[vIndex++] = pFree1.position.x * contentScale;
		    vertices[vIndex++] = pFree1.position.y * contentScale;
		    
                    colors[cIndex++] = 0;
                    colors[cIndex++] = 0;
                    colors[cIndex++] = 255;
                    colors[cIndex++] = 255;
                    
                    colors[cIndex++] = 0;
                    colors[cIndex++] = 0;
                    colors[cIndex++] = 255;
                    colors[cIndex++] = 255;
		}
		count ++;
	    }
	}
	
	count = 0;
	
	for (NSUInteger i=0; i<GRID_SIZE-1; i++) {
	    for (NSUInteger j=0; j<GRID_SIZE; j++) {
		CMTPParticle *pFree = [particles_free objectAtIndex:count];
		CMTPParticle *pFree1 = [particles_free objectAtIndex:count+GRID_SIZE];
		
		vertices[vIndex++] = pFree.position.x * contentScale;
		vertices[vIndex++] = pFree.position.y * contentScale;
		vertices[vIndex++] = pFree1.position.x * contentScale;
		vertices[vIndex++] = pFree1.position.y * contentScale;
		
                colors[cIndex++] = 0;
                colors[cIndex++] = 0;
                colors[cIndex++] = 255;
                colors[cIndex++] = 255;
                
                colors[cIndex++] = 0;
                colors[cIndex++] = 0;
                colors[cIndex++] = 255;
                colors[cIndex++] = 255;
		
		count ++;
	    }
	}
	
        glVertexAttribPointer(vertexAttrib, 2, GL_FLOAT, GL_FALSE, stride, vertices);
        glVertexAttribPointer(colorAttrib, 4, GL_UNSIGNED_BYTE, 1, 0, colors);
        glDrawArrays(GL_LINES, 0, vIndex/2);
        
        glDisableVertexAttribArray(vertexAttrib);
        glDisableVertexAttribArray(colorAttrib);
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
    particles_fixed = [[NSMutableArray alloc] init];
    particles_free = [[NSMutableArray alloc] init];
    CMTPVector3D gravityVector = CMTPVector3DMake(0.0, 0.0, 0.0);
    s = [[CMTPParticleSystem alloc] initWithGravityVector:gravityVector drag:0.2f];
    [s setIntegrator:CMTPParticleSystemIntegratorModifiedEuler];
    
    NSUInteger sx = (NSUInteger)CGRectGetMinX(frame);
    NSUInteger sy = (NSUInteger)CGRectGetMinY(frame);
    NSUInteger sp = (NSUInteger)CGRectGetWidth(frame) / GRID_SIZE;
    
    attractor = [[s makeParticleWithMass:1 position:CMTPVector3DMake(CGRectGetMidX(frame), CGRectGetMidY(frame), 0.0)] retain];
    [attractor makeFixed];
    
    float attractionStrength;
    float attractionMinDistance;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
	// iPad
	attractionStrength = -40000.0f;
	attractionMinDistance = 80.0f;
    }
    else {
	// iPhone
	attractionStrength = -3000.0f;
	attractionMinDistance = 35.0f;
    }
    
    // create grid of particles
    for (NSUInteger i=0; i<GRID_SIZE; i++) {
        for (NSUInteger j=0; j<GRID_SIZE; j++) {
            
            CMTPParticle *a = [s makeParticleWithMass:0.8f position:CMTPVector3DMake(sx+j*sp, sy+i*sp, 0.0f)];
            [a makeFixed];
            CMTPParticle *b = [s makeParticleWithMass:0.8f position:CMTPVector3DMake(sx+j*sp, sy+i*sp, 0.0f)];
            
            [particles_fixed addObject:a];
            [particles_free addObject:b];
            
            [s makeSpringBetweenParticleA:a particleB:b springConstant:0.1f damping:0.01f restLength:0.0f];
            [s makeAttractionBetweenParticleA:attractor particleB:b strength:attractionStrength minDistance:attractionMinDistance];
        }
    }
}

- (void)setupOpenGL
{
    EAGLContext *context = [[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2] autorelease];
    
    if (!context) {
        ALog(@"Failed to create ES context");
    }
    else if (![EAGLContext setCurrentContext:context]) {
        ALog(@"Failed to set ES context current");
    }
    ASSERT_GL_OK();
    
    [self.glView setContext:context];
    [self.glView setFramebuffer];
    
    NSError *error = nil;
    NSArray *attributeNames = [NSArray arrayWithObjects:@"position", @"color", @"textureCoord", nil];
    NSArray *uniformNames = [NSArray arrayWithObjects:@"mvp", @"sampler", @"colorOnly", nil];
    self.shaderProgram = [[[CMGLESKProgram alloc] init] autorelease];
    if (![self.shaderProgram loadProgramFromFilesVertexShader:@"AttractionGridVertexShader.glsl" fragmentShader:@"AttractionGridFragmentShader.glsl" attributeNames:attributeNames uniformNames:uniformNames error:&error]) {
        ALog(@"Shader program load failed: %@", error);
    }
    
    ASSERT_GL_OK();
    
    colorAttrib = (GLuint)[self.shaderProgram indexOfAttribute:@"color"];
    vertexAttrib = (GLuint)[self.shaderProgram indexOfAttribute:@"position"];
    textureCoordAttrib = (GLuint)[self.shaderProgram indexOfAttribute:@"textureCoord"];

    animating = NO;
    
    self.gridTexture = [CMGLESKTexture textureNamed:@"sandy_beach.jpg"];
    
    NSUInteger tIndex = 0;
    CGFloat imageGridSize = self.gridTexture.size.width / GRID_SIZE; // NOTE: assumes square image
    
    for (NSUInteger i=0; i<GRID_SIZE-1; i++) {
        for (NSUInteger j=0; j<GRID_SIZE-1; j++) {
            CGRect subRect = CGRectMake(imageGridSize*i, imageGridSize*j, imageGridSize, imageGridSize);
            CMGLESKTexCoord subTexRect = [gridTexture croppedTextureCoord:subRect];
            
            texCoords[tIndex++] = subTexRect.x1;
            texCoords[tIndex++] = subTexRect.y2;
            
            texCoords[tIndex++] = subTexRect.x2;
            texCoords[tIndex++] = subTexRect.y2;
            
            texCoords[tIndex++] = subTexRect.x1;
            texCoords[tIndex++] = subTexRect.y1;
            
            texCoords[tIndex++] = subTexRect.x2;
            texCoords[tIndex++] = subTexRect.y2;
            
            texCoords[tIndex++] = subTexRect.x1;
            texCoords[tIndex++] = subTexRect.y1;
            
            texCoords[tIndex++] = subTexRect.x2;
            texCoords[tIndex++] = subTexRect.y1;
        }
    }

    ASSERT_GL_OK();
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
        
	//[self.glView setFramebuffer];
	
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
    CGPoint location = [touch locationInView:self.view];
    mouseX = location.x;
    mouseY = self.view.bounds.size.height - location.y;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    mouseX = location.x;
    mouseY = self.view.bounds.size.height - location.y;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    mouseX = location.x;
    mouseY = self.view.bounds.size.height - location.y;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Attraction Grid";
    
    NSMutableArray *toolbarItems = [NSMutableArray array];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithCustomView:self.gridToggleView] autorelease]];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithCustomView:self.fpsLabel] autorelease]];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithCustomView:self.imageToggleView] autorelease]];
    
    self.toolbarItems = toolbarItems;
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    contentScale = glView.contentScaleFactor;
    [self setupOpenGL];
}

- (void)viewDidUnload
{
    [self setFpsLabel:nil];
    [self setFullFrameRateLabel:nil];
    [self setGlView:nil];
    [self setGridToggleView:nil];
    [self setImageToggleView:nil];
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!physicsSetupCompleted) {
        GLfloat viewWidth = CGRectGetWidth(self.glView.frame);
        GLfloat viewHeight = CGRectGetHeight(self.glView.frame);
        CGFloat gridWH = fminf(viewWidth, viewHeight) * 0.8f;   // width & height (square)
        CGRect gridFrame = CGRectIntegral(CGRectMake(viewWidth/2-gridWH/2, viewHeight/2-gridWH/2, gridWH, gridWH));
        [self setupPhysicsInFrame:gridFrame];
        physicsSetupCompleted = YES;
        
        mouseX = attractor.position.x;
        mouseY = attractor.position.y;
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
        showGrid = NO;
        showImage = YES;
        
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    // Tear down context.
    [self.glView setContext:nil];

    fullFrameRate = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [attractor release];
    [displayLink release];
    [fpsLabel release];
    [fullFrameRateLabel release];
    [glView release];
    [gridTexture release];
    [gridToggleView release];
    [imageToggleView release];
    [particles_fixed release];
    [particles_free release];
    [s release];
    [shaderProgram release];
    
    [super dealloc];
}

@end
