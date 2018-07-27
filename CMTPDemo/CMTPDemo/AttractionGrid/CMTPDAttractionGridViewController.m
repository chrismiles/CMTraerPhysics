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

#import "CMGLESKProgram.h"
#import "CMGLESKTexture.h"
#import "CMGLESKUtil.h"
#import "CMTPDAttractionGridViewController.h"
#import "CMTraerPhysics.h"
#import <QuartzCore/QuartzCore.h>

#define GRID_SIZE 32
#define NUM_GRID_VERTICES (2*(GRID_SIZE*GRID_SIZE+2*GRID_SIZE*(GRID_SIZE-1)))

#pragma mark - Static Globals
// Static globals so revisiting same demo remembers control settings.
static BOOL viewedBefore;
static BOOL showGrid;
static BOOL showImage;

#pragma mark - CMTPDAttractionGridViewController

@interface CMTPDAttractionGridViewController () {
    BOOL animating;
    BOOL fullFrameRate;

    CMTPFloat contentScale;
    CMTPFloat frameHeight,frameWidth;
    NSInteger animationFrameInterval;

    GLfloat mouseX;
    GLfloat mouseY;

    GLuint colorAttrib;
    GLuint textureCoordAttrib;
    GLuint vertexAttrib;

    GLfloat texCoords[6*2*(GRID_SIZE-1)*(GRID_SIZE-1)];

    // FPS
    double fps_prev_time;
    NSUInteger fps_count;
}

// Physics
@property (strong,nonatomic) CMTPParticle* attractor;
@property (strong,nonatomic) NSMutableArray* particles_fixed;
@property (strong,nonatomic) NSMutableArray* particles_free;
@property (strong,nonatomic) CMTPParticleSystem* s;

@property (strong,nonatomic) CADisplayLink* displayLink;
@property (strong,nonatomic) CMGLESKTexture* gridTexture;
@property (strong,nonatomic) CMGLESKProgram* shaderProgram;

@end

@implementation CMTPDAttractionGridViewController

#pragma mark - Full Frame Rate management

-(void)enableFullFrameRate {
    _fullFrameRateLabel.hidden=NO;
    fullFrameRate=YES;
}

-(void)disableFullFrameRate {
    _fullFrameRateLabel.hidden=YES;
    fullFrameRate=NO;
    [self startAnimation];
}

#pragma mark - Control actions

-(IBAction)gridToggleAction:(id)sender {
    UISwitch* aSwitch=(UISwitch*)sender;
    showGrid=aSwitch.on;
    if (showGrid&&!animating) {
        [self disableFullFrameRate];
        [self startAnimation];
    }
}

-(IBAction)imageToggleAction:(id)sender {
    UISwitch* aSwitch=(UISwitch*)sender;
    showImage=aSwitch.on;
    if (showImage&&!animating) {
        [self disableFullFrameRate];
        [self startAnimation];
    }
}

#pragma mark - OpenGL rendering

-(void)drawFrame:(id)sender {
    [_testView setFramebuffer];

    /* FPS */
    double curr_time=CACurrentMediaTime();
    if (curr_time-fps_prev_time>=0.2) {
        double delta=(curr_time-fps_prev_time)/fps_count;
        _fpsLabel.title=[NSString stringWithFormat:@"%0.0f fps",1.0/delta];
        fps_prev_time=curr_time;
        fps_count=1;
    } else {
        fps_count++;
    }
    /* *** AttractionGrid **** */

    [_s tick:1];

    _attractor.position=CMTPVector3DMake(mouseX,mouseY,0);
    if (fullFrameRate) {
        // Simulate at full frame rate; skip rendering as there's nothing to draw
        if (animating) {
            [self stopAnimation];
        }
        [self performSelector:@selector(drawFrame:) withObject:nil afterDelay:0.0];
        return;
    }
    /* GL rendering */

    glClearColor(0.2f,0.2f,0.2f,1.0f);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    glUseProgram(_shaderProgram.program);
    ASSERT_GL_OK();

    GLfloat projectionMatrix[16];
    orthoMatrix(projectionMatrix,0.0f,(float)frameWidth,0.0f,(float)frameHeight,-1.0f,1.0f);
    int uniformMVP=[_shaderProgram indexOfUniform:@"mvp"];
    glUniformMatrix4fv(uniformMVP,1,GL_FALSE,projectionMatrix);
    ASSERT_GL_OK();
    if (showImage) {
        GLfloat vertices[6*2*(GRID_SIZE-1)*(GRID_SIZE-1)];

        NSUInteger vIndex=0;
        for (NSUInteger i=0;i<GRID_SIZE-1;i++) {
            for (NSUInteger j=0;j<GRID_SIZE-1;j++) {
                CMTPParticle* pBotLeft=[_particles_free objectAtIndex:(GRID_SIZE-1-j-1)*GRID_SIZE+i];
                CMTPParticle* pBotRight=[_particles_free objectAtIndex:(GRID_SIZE-1-j-1)*GRID_SIZE+i+1];
                CMTPParticle* pTopLeft=[_particles_free objectAtIndex:(GRID_SIZE-1-j)*GRID_SIZE+i];
                CMTPParticle* pTopRight=[_particles_free objectAtIndex:(GRID_SIZE-1-j)*GRID_SIZE+i+1];

                vertices[vIndex++]=(GLfloat)(pBotLeft.position.x*contentScale);
                vertices[vIndex++]=(GLfloat)(pBotLeft.position.y*contentScale);

                vertices[vIndex++]=(GLfloat)(pBotRight.position.x*contentScale);
                vertices[vIndex++]=(GLfloat)(pBotRight.position.y*contentScale);

                vertices[vIndex++]=(GLfloat)(pTopLeft.position.x*contentScale);
                vertices[vIndex++]=(GLfloat)(pTopLeft.position.y*contentScale);

                vertices[vIndex++]=(GLfloat)(pBotRight.position.x*contentScale);
                vertices[vIndex++]=(GLfloat)(pBotRight.position.y*contentScale);

                vertices[vIndex++]=(GLfloat)(pTopLeft.position.x*contentScale);
                vertices[vIndex++]=(GLfloat)(pTopLeft.position.y*contentScale);

                vertices[vIndex++]=(GLfloat)(pTopRight.position.x*contentScale);
                vertices[vIndex++]=(GLfloat)(pTopRight.position.y*contentScale);
            }
        }
        glUniform1i([_shaderProgram indexOfUniform:@"colorOnly"],GL_FALSE);

        int stride=0;

        glEnableVertexAttribArray(vertexAttrib); // vertex coords
        glVertexAttribPointer(vertexAttrib,2,GL_FLOAT,GL_FALSE,stride,vertices);
        glEnableVertexAttribArray(textureCoordAttrib); // texture coords
        glVertexAttribPointer(textureCoordAttrib,2,GL_FLOAT,GL_FALSE,stride,texCoords);

        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D,_gridTexture.glTextureName);
        glUniform1i([_shaderProgram indexOfUniform:@"sampler"],0);

        //glDrawArrays(GL_TRIANGLE_STRIP, 0, vIndex/2);
        glDrawArrays(GL_TRIANGLES,0,(GLsizei)(vIndex/2));

        glDisableVertexAttribArray(textureCoordAttrib);
        glDisableVertexAttribArray(vertexAttrib);
    }
    if (showGrid) {
        GLfloat vertices[2*NUM_GRID_VERTICES];
        GLubyte colors[4*NUM_GRID_VERTICES];
        NSUInteger vIndex=0;
        NSUInteger cIndex=0;

        glUniform1i([_shaderProgram indexOfUniform:@"colorOnly"],GL_TRUE);

        int stride=0;
        glEnableVertexAttribArray(vertexAttrib); // vertex coords
        glEnableVertexAttribArray(colorAttrib);  // colors
        ASSERT_GL_OK();

        NSUInteger pfixed_count=[_particles_fixed count];
        for (NSUInteger i=0;i<pfixed_count;i++) {
            CMTPParticle* pFixed=[_particles_fixed objectAtIndex:i];
            CMTPParticle* pFree=[_particles_free objectAtIndex:i];

            vertices[vIndex++]=(GLfloat)(pFixed.position.x*contentScale);
            vertices[vIndex++]=(GLfloat)(pFixed.position.y*contentScale);
            vertices[vIndex++]=(GLfloat)(pFree.position.x*contentScale);
            vertices[vIndex++]=(GLfloat)(pFree.position.y*contentScale);

            colors[cIndex++]=255;
            colors[cIndex++]=0;
            colors[cIndex++]=0;
            colors[cIndex++]=255;

            colors[cIndex++]=255;
            colors[cIndex++]=0;
            colors[cIndex++]=0;
            colors[cIndex++]=255;
        }
        NSUInteger count=0;
        for (NSUInteger i=0;i<GRID_SIZE;i++) {
            for (NSUInteger j=0;j<GRID_SIZE;j++) {
                if (j<GRID_SIZE-1) {
                    CMTPParticle* pFree=[_particles_free objectAtIndex:count];
                    CMTPParticle* pFree1=[_particles_free objectAtIndex:count+1];

                    vertices[vIndex++]=(GLfloat)(pFree.position.x*contentScale);
                    vertices[vIndex++]=(GLfloat)(pFree.position.y*contentScale);
                    vertices[vIndex++]=(GLfloat)(pFree1.position.x*contentScale);
                    vertices[vIndex++]=(GLfloat)(pFree1.position.y*contentScale);

                    colors[cIndex++]=0;
                    colors[cIndex++]=0;
                    colors[cIndex++]=255;
                    colors[cIndex++]=255;

                    colors[cIndex++]=0;
                    colors[cIndex++]=0;
                    colors[cIndex++]=255;
                    colors[cIndex++]=255;
                }
                count++;
            }
        }
        count=0;
        for (NSUInteger i=0;i<GRID_SIZE-1;i++) {
            for (NSUInteger j=0;j<GRID_SIZE;j++) {
                CMTPParticle* pFree=[_particles_free objectAtIndex:count];
                CMTPParticle* pFree1=[_particles_free objectAtIndex:count+GRID_SIZE];

                vertices[vIndex++]=(GLfloat)(pFree.position.x*contentScale);
                vertices[vIndex++]=(GLfloat)(pFree.position.y*contentScale);
                vertices[vIndex++]=(GLfloat)(pFree1.position.x*contentScale);
                vertices[vIndex++]=(GLfloat)(pFree1.position.y*contentScale);

                colors[cIndex++]=0;
                colors[cIndex++]=0;
                colors[cIndex++]=255;
                colors[cIndex++]=255;

                colors[cIndex++]=0;
                colors[cIndex++]=0;
                colors[cIndex++]=255;
                colors[cIndex++]=255;

                count++;
            }
        }
        glVertexAttribPointer(vertexAttrib,2,GL_FLOAT,GL_FALSE,stride,vertices);
        glVertexAttribPointer(colorAttrib,4,GL_UNSIGNED_BYTE,1,0,colors);
        glDrawArrays(GL_LINES,0,(GLsizei)(vIndex/2));

        glDisableVertexAttribArray(vertexAttrib);
        glDisableVertexAttribArray(colorAttrib);
    } /* showGrid */

    [_testView.context presentRenderbuffer:GL_RENDERBUFFER];
    if (!showGrid&&!showImage) {
        [self enableFullFrameRate];
    }
}

#pragma mark - Setup

-(void)setupPhysicsInFrame:(CGRect)frame {
    /* AttractionGrid - creates a square grid */
    self.particles_fixed=[[NSMutableArray alloc] init];
    self.particles_free=[[NSMutableArray alloc] init];
    CMTPVector3D gravityVector=CMTPVector3DMake(0.0,0.0,0.0);
    self.s=[[CMTPParticleSystem alloc] initWithGravityVector:gravityVector drag:0.2f];
    [_s setIntegrator:CMTPParticleSystemIntegratorModifiedEuler];

    NSUInteger sx=(NSUInteger)CGRectGetMinX(frame);
    NSUInteger sy=(NSUInteger)CGRectGetMinY(frame);
    NSUInteger sp=(NSUInteger)CGRectGetWidth(frame)/GRID_SIZE;

    self.attractor=[_s makeParticleWithMass:1 position:CMTPVector3DMake(CGRectGetMidX(frame),CGRectGetMidY(frame),0.0)];
    [_attractor makeFixed];

    CMTPFloat attractionStrength;
    CMTPFloat attractionMinDistance;
    if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
        // iPad
        attractionStrength=-40000.0f;
        attractionMinDistance=80.0f;
    } else {
        // iPhone
        attractionStrength=-3000.0f;
        attractionMinDistance=35.0f;
    }
    // create grid of particles
    for (NSUInteger i=0;i<GRID_SIZE;i++) {
        for (NSUInteger j=0;j<GRID_SIZE;j++) {
            CMTPParticle* a=[_s makeParticleWithMass:0.8f position:CMTPVector3DMake(sx+j*sp,sy+i*sp,0.0f)];
            [a makeFixed];
            CMTPParticle* b=[_s makeParticleWithMass:0.8f position:CMTPVector3DMake(sx+j*sp,sy+i*sp,0.0f)];

            [_particles_fixed addObject:a];
            [_particles_free addObject:b];

            [_s makeSpringBetweenParticleA:a particleB:b springConstant:0.1f damping:0.01f restLength:0.0f];
            [_s makeAttractionBetweenParticleA:_attractor particleB:b strength:attractionStrength minDistance:attractionMinDistance];
        }
    }
}

-(void)setupOpenGL {
    EAGLContext* context=[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context) {
        ALog(@"Failed to create ES context");
    } else if (![EAGLContext setCurrentContext:context]) {
        ALog(@"Failed to set ES context current");
    }
    ASSERT_GL_OK();

    [_testView setContext:context];
    [_testView setFramebuffer];

    NSError* error=nil;
    NSArray* attributeNames=[NSArray arrayWithObjects:@"position",@"color",@"textureCoord",nil];
    NSArray* uniformNames=[NSArray arrayWithObjects:@"mvp",@"sampler",@"colorOnly",nil];
    _shaderProgram=[[CMGLESKProgram alloc] init];
    if (![_shaderProgram loadProgramFromFilesVertexShader:@"AttractionGridVertexShader.glsl" fragmentShader:@"AttractionGridFragmentShader.glsl" attributeNames:attributeNames uniformNames:uniformNames error:&error]) {
        ALog(@"Shader program load failed: %@",error);
    }
    ASSERT_GL_OK();

    colorAttrib=(GLuint)[_shaderProgram indexOfAttribute:@"color"];
    vertexAttrib=(GLuint)[_shaderProgram indexOfAttribute:@"position"];
    textureCoordAttrib=(GLuint)[_shaderProgram indexOfAttribute:@"textureCoord"];

    _gridTexture=[CMGLESKTexture textureNamed:@"sandy_beach.jpg"];

    NSUInteger tIndex=0;
    CGFloat imageGridSize=_gridTexture.size.width/GRID_SIZE;     // NOTE: assumes square image
    for (NSUInteger i=0;i<GRID_SIZE-1;i++) {
        for (NSUInteger j=0;j<GRID_SIZE-1;j++) {
            CGRect subRect=CGRectMake(imageGridSize*i,imageGridSize*j,imageGridSize,imageGridSize);
            CMGLESKTexCoord subTexRect=[_gridTexture croppedTextureCoord:subRect];

            texCoords[tIndex++]=subTexRect.x1;
            texCoords[tIndex++]=subTexRect.y2;

            texCoords[tIndex++]=subTexRect.x2;
            texCoords[tIndex++]=subTexRect.y2;

            texCoords[tIndex++]=subTexRect.x1;
            texCoords[tIndex++]=subTexRect.y1;

            texCoords[tIndex++]=subTexRect.x2;
            texCoords[tIndex++]=subTexRect.y2;

            texCoords[tIndex++]=subTexRect.x1;
            texCoords[tIndex++]=subTexRect.y1;

            texCoords[tIndex++]=subTexRect.x2;
            texCoords[tIndex++]=subTexRect.y1;
        }
    }
    ASSERT_GL_OK();
}

#pragma mark - Animation management

-(void)startAnimation {
    if (!animating) {
        self.displayLink=[[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(drawFrame:)];
        if (@available(iOS 10.0, *)) {
            [_displayLink setPreferredFramesPerSecond:animationFrameInterval];
        } else {
            [_displayLink setFrameInterval:animationFrameInterval];
        }
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

        [_testView setFramebuffer];

        animating=YES;
    }
}

-(void)stopAnimation {
    if (animating) {
        [_displayLink invalidate];
        self.displayLink=nil;
        animating=NO;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(drawFrame:) object:nil];
}

-(NSInteger)animationFrameInterval {
    return animationFrameInterval;
}

-(void)setAnimationFrameInterval:(NSInteger)frameInterval {
    /*
       Frame interval defines how many display frames must pass between each time the display link fires.
       The display link will only fire 30 times a second when the frame internal is two on a display that refreshes 60 times a second. The default frame interval setting of one will fire 60 times a second when the display refreshes at 60 times a second. A frame interval setting of less than one results in undefined behavior.
     */
    if (frameInterval>=1) {
        animationFrameInterval=frameInterval;
        if (animating) {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

#pragma mark - EAGLViewDelegate methods

-(void)eaglView:(EAGLView*)eaglView framebufferCreatedWithSize:(CGSize)framebufferSize {
    frameWidth=framebufferSize.width;
    frameHeight=framebufferSize.height;
    contentScale=eaglView.contentScaleFactor;
}

#pragma mark - Application state changes

-(void)applicationWillResignActiveNotification:(NSNotification*)notification {
    [self stopAnimation];
}

-(void)applicationDidBecomeActiveNotification:(NSNotification*)notification {
    [self startAnimation];
}

#pragma mark - Touches

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch* touch=[touches anyObject];
    CGPoint location=[touch locationInView:_testView];
    mouseX=(GLfloat)location.x;
    mouseY=(GLfloat)(_testView.bounds.size.height-location.y);
}

-(void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch* touch=[touches anyObject];
    CGPoint location=[touch locationInView:_testView];
    mouseX=(GLfloat)location.x;
    mouseY=(GLfloat)(_testView.bounds.size.height-location.y);
}

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch* touch=[touches anyObject];
    CGPoint location=[touch locationInView:_testView];
    mouseX=(GLfloat)location.x;
    mouseY=(GLfloat)(_testView.bounds.size.height-location.y);
}

-(void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
}

#pragma mark - View lifecycle

-(void)viewDidLoad {
    [super viewDidLoad];
    // Setting delegate here avoids seeing VC renamed to "Delegate" in IB.
    _testView.delegate=self;
    if (!viewedBefore) {
        showGrid=_gridSwitch.on;
        showImage=_imageSwitch.on;
        viewedBefore=YES;
    } else {
        _gridSwitch.on=showGrid;
        _imageSwitch.on=showImage;
    };
    [self.navigationController setToolbarHidden:NO animated:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self physicsSetup];
    });
}

-(void)physicsSetup {
    contentScale=_testView.contentScaleFactor;
    GLfloat viewWidth=(GLfloat)CGRectGetWidth(_testView.frame);
    GLfloat viewHeight=(GLfloat)CGRectGetHeight(_testView.frame);
    CGFloat gridWH=fminf(viewWidth,viewHeight)*0.8f;        // width & height (square)
    CGRect gridFrame=CGRectIntegral(CGRectMake(viewWidth/2-gridWH/2,viewHeight/2-gridWH/2,gridWH,gridWH));
    [self setupPhysicsInFrame:gridFrame];
    mouseX=(GLfloat)_attractor.position.x;
    mouseY=(GLfloat)_attractor.position.y;
    [self setupOpenGL];
    fps_prev_time=CACurrentMediaTime();
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self startAnimation];
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id)coordinator {
    // before rotation
    UISplitViewController *splitViewController=self.splitViewController;
    UINavigationController *navigationController=splitViewController.viewControllers[0];
    UIViewController* masterViewController=navigationController.viewControllers[0];
    [masterViewController.navigationController popToRootViewControllerAnimated:NO];
    [coordinator animateAlongsideTransition:^(id  _Nonnull context) {
        // resize our content view ...
     } completion:^(id  _Nonnull context) {
        // after rotation
        [masterViewController performSegueWithIdentifier:@"attractionGridSegue" sender:nil];
    }];
}

-(void)viewDidDisappear:(BOOL)animated {
    [self stopAnimation];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidDisappear:animated];
}

#pragma mark - Object lifecycle

-(void)dealloc {
    // Tear down context.
    [_testView setContext:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

@end

