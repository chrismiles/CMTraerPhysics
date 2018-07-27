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

#import "CMGLESKMatrix3D.h"
#import "CMGLESKProgram.h"
#import "CMGLESKTexture.h"
#import "CMGLESKUtil.h"
#import "CMTPDClothTestViewController.h"
#import "CMTraerPhysics.h"
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>

#pragma mark - Static Globals
// Static globals so revisiting same demo remembers control settings.
static BOOL viewedBefore;
static BOOL showGrid;
static BOOL showImage;
static BOOL showAccel;

#pragma mark - C Functions

static GLfloat* circle_vertices(unsigned int* count,CMTPFloat radius,unsigned int num_sections){
    GLfloat* vertices;
    unsigned int index=0;

    *count=2*(2+num_sections);
    vertices=malloc(sizeof(GLfloat)* * count);

    vertices[index++]=0.0f;
    vertices[index++]=0.0f;
    for (NSUInteger i=0;i<num_sections+1;i++) {
        vertices[index++]=(GLfloat)(radius*cos(i*2*M_PI/num_sections));
        vertices[index++]=(GLfloat)(radius*sin(i*2*M_PI/num_sections));
    }
    ZAssert(index<=*count,@"vertices array was too small");

    return vertices;
}

@interface CMTPDClothTestViewController () {
    BOOL animating;
    BOOL fullFrameRate;

    CMTPFloat contentScale;
    CMTPFloat frameHeight,frameWidth;
    NSInteger animationFrameInterval;

    NSUInteger grabbedHandle;
    CGPoint handle1;
    CGPoint handle2;

    GLuint textureCoordAttrib;
    GLuint vertexAttrib;

    GLuint handle_vbo;
    unsigned int handleCount;

    GLfloat projectionMatrix[16];

    CMTPFloat gravityScale;
    NSUInteger gridSize;
    NSUInteger numGridVertices;
    GLfloat* texCoords;
    GLfloat* texVertices;
    GLfloat* gridVertices;

    // FPS
    double fps_prev_time;
    NSUInteger fps_count;

}

@property (strong,nonatomic) CMMotionManager* motionManager;

// Physics
@property (strong,nonatomic) CMTPParticle* attractor;
@property (strong,nonatomic) NSMutableArray* particles;
@property (strong,nonatomic) CMTPParticleSystem* s;

@property (strong,nonatomic) CADisplayLink* displayLink;
@property (strong,nonatomic) CMGLESKTexture* gridTexture;
@property (strong,nonatomic) CMGLESKProgram* shaderProgram;

@end

@implementation CMTPDClothTestViewController

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

-(IBAction)accelToggleAction:(id)sender {
    UISwitch* aSwitch=(UISwitch*)sender;
    showAccel=aSwitch.on;
    if (showAccel) {
        if ([_motionManager isDeviceMotionAvailable]) {
            [_motionManager startDeviceMotionUpdates];
        }
    } else {
        if ([_motionManager isDeviceMotionActive]) {
            [_motionManager stopDeviceMotionUpdates];
        }
    }
}

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
    /* *** Cloth Test **** */

    {
        CMTPParticle* p1=[_particles objectAtIndex:0];
        CMTPParticle* p2=[_particles objectAtIndex:gridSize-1];
        p1.position=CMTPVector3DMake(handle1.x,handle1.y,0.0f);
        p2.position=CMTPVector3DMake(handle2.x,handle2.y,0.0f);
    }
    if (_motionManager.isDeviceMotionActive) {
        CMAcceleration gravity=_motionManager.deviceMotion.gravity;
        CMTPFloat x=(CMTPFloat)(gravity.x)*gravityScale;
        CMTPFloat y=(CMTPFloat)(-gravity.y)*gravityScale;
        switch ([[UIApplication sharedApplication] statusBarOrientation]) {
            case UIInterfaceOrientationLandscapeLeft:
            {
                CMTPFloat t=y;
                y=x;
                x=-t;
            };
                break;
            case UIInterfaceOrientationLandscapeRight:
            {
                CMTPFloat t=y;
                y=-x;
                x=t;
            };
                break;
            default:
                break;
        }
        CMTPVector3D gravityVector=CMTPVector3DMake(x,y,0.0f);
        _s.gravity=gravityVector;
    }
    [_s tick:1];
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

    int uniformMVP=[_shaderProgram indexOfUniform:@"mvp"];
    if (showImage||showGrid) {
        /* Draw grab handles */
        Matrix3D translationMatrix,mvpMatrix;
        glUniform1i([_shaderProgram indexOfUniform:@"colorOnly"],GL_TRUE);
        glUniform4f([_shaderProgram indexOfUniform:@"color"],0.8f,0.8f,0.8f,1.0f);

        glBindBuffer(GL_ARRAY_BUFFER,handle_vbo);
        glEnableVertexAttribArray(vertexAttrib);
        glVertexAttribPointer(vertexAttrib,2,GL_FLOAT,GL_FALSE,0,0);

        Matrix3DSetTranslation(translationMatrix,(GLfloat)(handle1.x*contentScale),(GLfloat)(handle1.y*contentScale),0.0f);
        Matrix3DMultiply(projectionMatrix,translationMatrix,mvpMatrix);
        glUniformMatrix4fv(uniformMVP,1,GL_FALSE,mvpMatrix);
        glDrawArrays(GL_TRIANGLE_FAN,0,(GLsizei)handleCount);

        Matrix3DSetTranslation(translationMatrix,(GLfloat)(handle2.x*contentScale),(GLfloat)(handle2.y*contentScale),0.0f);
        Matrix3DMultiply(projectionMatrix,translationMatrix,mvpMatrix);
        glUniformMatrix4fv(uniformMVP,1,GL_FALSE,mvpMatrix);
        glDrawArrays(GL_TRIANGLE_FAN,0,(GLsizei)handleCount);

        glDisableVertexAttribArray(vertexAttrib);
        glBindBuffer(GL_ARRAY_BUFFER,0);
        ASSERT_GL_OK();
    }
    /* Reset mvp */
    glUniformMatrix4fv(uniformMVP,1,GL_FALSE,projectionMatrix);
    ASSERT_GL_OK();
    if (showImage) {
        NSUInteger vIndex=0;
        for (NSUInteger i=0;i<gridSize-1;i++) {
            for (NSUInteger j=0;j<gridSize-1;j++) {
                CMTPParticle* pBotLeft=[_particles objectAtIndex:(gridSize-1-j-1)*gridSize+i];
                CMTPParticle* pBotRight=[_particles objectAtIndex:(gridSize-1-j-1)*gridSize+i+1];
                CMTPParticle* pTopLeft=[_particles objectAtIndex:(gridSize-1-j)*gridSize+i];
                CMTPParticle* pTopRight=[_particles objectAtIndex:(gridSize-1-j)*gridSize+i+1];

                texVertices[vIndex++]=(GLfloat)(pBotLeft.position.x*contentScale);
                texVertices[vIndex++]=(GLfloat)(pBotLeft.position.y*contentScale);

                texVertices[vIndex++]=(GLfloat)(pBotRight.position.x*contentScale);
                texVertices[vIndex++]=(GLfloat)(pBotRight.position.y*contentScale);

                texVertices[vIndex++]=(GLfloat)(pTopLeft.position.x*contentScale);
                texVertices[vIndex++]=(GLfloat)(pTopLeft.position.y*contentScale);

                texVertices[vIndex++]=(GLfloat)(pBotRight.position.x*contentScale);
                texVertices[vIndex++]=(GLfloat)(pBotRight.position.y*contentScale);

                texVertices[vIndex++]=(GLfloat)(pTopLeft.position.x*contentScale);
                texVertices[vIndex++]=(GLfloat)(pTopLeft.position.y*contentScale);

                texVertices[vIndex++]=(GLfloat)(pTopRight.position.x*contentScale);
                texVertices[vIndex++]=(GLfloat)(pTopRight.position.y*contentScale);
            }
        }
        glUniform1i([_shaderProgram indexOfUniform:@"colorOnly"],GL_FALSE);

        int stride=0;

        glEnableVertexAttribArray(vertexAttrib); // vertex coords
        glVertexAttribPointer(vertexAttrib,2,GL_FLOAT,GL_FALSE,stride,texVertices);
        glEnableVertexAttribArray(textureCoordAttrib); // texture coords
        glVertexAttribPointer(textureCoordAttrib,2,GL_FLOAT,GL_FALSE,stride,texCoords);

        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D,_gridTexture.glTextureName);
        glUniform1i([_shaderProgram indexOfUniform:@"sampler"],0);

        glDrawArrays(GL_TRIANGLES,0,(GLsizei)(vIndex/2));

        glDisableVertexAttribArray(textureCoordAttrib);
        glDisableVertexAttribArray(vertexAttrib);
    }
    if (showGrid) {
        NSUInteger vIndex=0;

        glUniform1i([_shaderProgram indexOfUniform:@"colorOnly"],GL_TRUE);
        glUniform4f([_shaderProgram indexOfUniform:@"color"],1.0f,1.0f,1.0f,1.0f);

        int stride=0;
        glEnableVertexAttribArray(vertexAttrib); // vertex coords
        ASSERT_GL_OK();

        NSUInteger count=0;
        for (NSUInteger i=0;i<gridSize;i++) {
            for (NSUInteger j=0;j<gridSize;j++) {
                if (j<gridSize-1) {
                    CMTPParticle* p1=[_particles objectAtIndex:count];
                    CMTPParticle* p2=[_particles objectAtIndex:count+1];

                    gridVertices[vIndex++]=(GLfloat)(p1.position.x*contentScale);
                    gridVertices[vIndex++]=(GLfloat)(p1.position.y*contentScale);
                    gridVertices[vIndex++]=(GLfloat)(p2.position.x*contentScale);
                    gridVertices[vIndex++]=(GLfloat)(p2.position.y*contentScale);
                }
                count++;
            }
        }
        count=0;
        for (NSUInteger i=0;i<gridSize-1;i++) {
            for (NSUInteger j=0;j<gridSize;j++) {
                CMTPParticle* p1=[_particles objectAtIndex:count];
                CMTPParticle* p2=[_particles objectAtIndex:count+gridSize];

                gridVertices[vIndex++]=(GLfloat)(p1.position.x*contentScale);
                gridVertices[vIndex++]=(GLfloat)(p1.position.y*contentScale);
                gridVertices[vIndex++]=(GLfloat)(p2.position.x*contentScale);
                gridVertices[vIndex++]=(GLfloat)(p2.position.y*contentScale);

                count++;
            }
        }
        glVertexAttribPointer(vertexAttrib,2,GL_FLOAT,GL_FALSE,stride,gridVertices);
        glDrawArrays(GL_LINES,0,(GLsizei)(vIndex/2));

        glDisableVertexAttribArray(vertexAttrib);
    } /* showGrid */

    [_testView.context presentRenderbuffer:GL_RENDERBUFFER];
    if (!showGrid&&!showImage) {
        [self enableFullFrameRate];
    }
}

#pragma mark - Setup

-(void)setupPhysicsInFrame:(CGRect)frame {
    /* AttractionGrid - creates a square grid */
    self.particles=[[NSMutableArray alloc] init];
    gravityScale=1.0f*CGRectGetHeight(self.testView.frame)/320.0f;
    CMTPVector3D gravityVector=CMTPVector3DMake(0.0f,gravityScale,0.0f);
    self.s=[[CMTPParticleSystem alloc] initWithGravityVector:gravityVector drag:0.06f];
    [_s setIntegrator:CMTPParticleSystemIntegratorRungeKutta];

    NSUInteger sp=(NSUInteger)(CGRectGetWidth(frame)/gridSize/1.5);
    NSUInteger sx=(NSUInteger)(CGRectGetWidth(frame)/2.0f-sp*gridSize/2.0f);
    NSUInteger sy=(NSUInteger)(CGRectGetHeight(frame)*0.15f);
    // create grid of particles
    for (NSUInteger i=0;i<gridSize;i++) {
        for (NSUInteger j=0;j<gridSize;j++) {
            CMTPParticle* p=[_s makeParticleWithMass:0.8f position:CMTPVector3DMake(sx+j*sp,sy+i*sp,0.0f)];
            [_particles addObject:p];
        }
    }
    // create springs
    for (NSUInteger i=0;i<gridSize;i++) {   //horizontal
        for (NSUInteger j=0;j<gridSize-1;j++) {
            CMTPParticle* particleA=[_particles objectAtIndex:(i*gridSize+j)];
            CMTPParticle* particleB=[_particles objectAtIndex:(i*gridSize+j+1)];
            [_s makeSpringBetweenParticleA:particleA particleB:particleB springConstant:1.0f damping:0.6f restLength:sp];
        }
    }
    for (NSUInteger i=0;i<gridSize-1;i++) {   //vertical
        for (NSUInteger j=0;j<gridSize;j++) {
            CMTPParticle* particleA=[_particles objectAtIndex:(i*gridSize+j)];
            CMTPParticle* particleB=[_particles objectAtIndex:((i+1)*gridSize+j)];
            [_s makeSpringBetweenParticleA:particleA particleB:particleB springConstant:1.0f damping:0.6f restLength:sp];
        }
    }
    CMTPParticle* particle=[_particles objectAtIndex:0];
    [particle makeFixed];
    handle1.x=particle.position.x;
    handle1.y=particle.position.y;

    particle=[_particles objectAtIndex:gridSize-1];
    [particle makeFixed];
    handle2.x=particle.position.x;
    handle2.y=particle.position.y;
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
    NSArray* attributeNames=[NSArray arrayWithObjects:@"position",@"textureCoord",nil];
    NSArray* uniformNames=[NSArray arrayWithObjects:@"color",@"colorOnly",@"mvp",@"sampler",nil];
    _shaderProgram=[[CMGLESKProgram alloc] init];
    if (![_shaderProgram loadProgramFromFilesVertexShader:@"ClothTestVertexShader.glsl" fragmentShader:@"ClothTestFragmentShader.glsl" attributeNames:attributeNames uniformNames:uniformNames error:&error]) {
        ALog(@"Shader program load failed: %@",error);
    }
    ASSERT_GL_OK();

    vertexAttrib=(GLuint)[_shaderProgram indexOfAttribute:@"position"];
    textureCoordAttrib=(GLuint)[_shaderProgram indexOfAttribute:@"textureCoord"];

    _gridTexture=[CMGLESKTexture textureNamed:@"sandy_beach.jpg"];

    NSUInteger tIndex=0;
    CGFloat imageGridSize=_gridTexture.size.width/gridSize;     // NOTE: assumes square image
    for (NSUInteger i=0;i<gridSize-1;i++) {
        for (NSUInteger j=0;j<gridSize-1;j++) {
            CGRect subRect=CGRectMake(imageGridSize*i,imageGridSize*(gridSize-j-1),imageGridSize,imageGridSize);
            CMGLESKTexCoord subTexRect=[_gridTexture croppedTextureCoord:subRect];

            texCoords[tIndex++]=subTexRect.x1;
            texCoords[tIndex++]=subTexRect.y1;

            texCoords[tIndex++]=subTexRect.x2;
            texCoords[tIndex++]=subTexRect.y1;

            texCoords[tIndex++]=subTexRect.x1;
            texCoords[tIndex++]=subTexRect.y2;

            texCoords[tIndex++]=subTexRect.x2;
            texCoords[tIndex++]=subTexRect.y1;

            texCoords[tIndex++]=subTexRect.x1;
            texCoords[tIndex++]=subTexRect.y2;

            texCoords[tIndex++]=subTexRect.x2;
            texCoords[tIndex++]=subTexRect.y2;
        }
    }
    // Grab handle
    GLfloat* handleVertices=circle_vertices(&handleCount,5.0f*contentScale,10);

    glGenBuffers(1,&handle_vbo);
    glBindBuffer(GL_ARRAY_BUFFER,handle_vbo);
    glBufferData(GL_ARRAY_BUFFER,(GLsizeiptr)(handleCount*sizeof(GL_FLOAT)),handleVertices,GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER,0);  // unbind
    ASSERT_GL_OK();

    free(handleVertices);
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

    orthoMatrix(projectionMatrix,0.0f,(float)frameWidth,(float)frameHeight,0.0f,-1.0f,1.0f);       // inverted Y
}

#pragma mark - Application state changes

-(void)applicationWillResignActiveNotification:(NSNotification*)notification {
    [self stopAnimation];
}

-(void)applicationDidBecomeActiveNotification:(NSNotification*)notification {
    [self startAnimation];
}

#pragma mark - Touches

-(void)moveHandle:(NSUInteger)handle toLocation:(CGPoint)location {
    if (location.x<0) {
        location.x=0;
    }
    if (location.y<0) {
        location.y=0;
    }
    if (location.x>=frameWidth) {
        location.x=frameWidth-1;
    }
    if (location.y>=frameHeight) {
        location.y=frameHeight-1;
    }
    if (1==handle) {
        handle1.x=location.x;
        handle1.y=location.y;
    } else if (2==handle) {
        handle2.x=location.x;
        handle2.y=location.y;
    }
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch* touch=[touches anyObject];
    CGPoint location=[touch locationInView:self.testView];
    CGPoint diff1=CGPointMake(location.x-handle1.x,location.y-handle1.y);
    CGPoint diff2=CGPointMake(location.x-handle2.x,location.y-handle2.y);
    CGFloat distance1=sqrt(diff1.x*diff1.x+diff1.y*diff1.y);
    CGFloat distance2=sqrt(diff2.x*diff2.x+diff2.y*diff2.y);
    if (distance1<24.0f) {
        grabbedHandle=1;
    } else if (distance2<24.0f) {
        grabbedHandle=2;
    }
    if (grabbedHandle>0) {
        [self moveHandle:grabbedHandle toLocation:location];
    }
}

-(void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch* touch=[touches anyObject];
    CGPoint location=[touch locationInView:self.testView];
    [self moveHandle:grabbedHandle toLocation:location];
}

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    grabbedHandle=0;
}

-(void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
    grabbedHandle=0;
}

#pragma mark - View lifecycle

-(void)viewDidLoad {
    [super viewDidLoad];
    // Setting delegate here avoids seeing VC renamed to "Delegate" in IB.
    self.testView.delegate=self;
    if (!viewedBefore) {
        showGrid=_gridSwitch.on;
        showImage=_imageSwitch.on;
        showAccel=_accelSwitch.on;
        viewedBefore=YES;
    } else {
        _gridSwitch.on=showGrid;
        _imageSwitch.on=showImage;
        _accelSwitch.on=showAccel;
    };
    [self.navigationController setToolbarHidden:NO animated:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self physicsSetup];
    });
}

-(void)physicsSetup {
    contentScale=_testView.contentScaleFactor;
    showGrid=_gridSwitch.isOn;
    showImage=_imageSwitch.isOn;
    gridSize=8;
    numGridVertices=2*(gridSize*gridSize+2*gridSize*(gridSize-1));
    //DLog(@"gridSize=%d numGridVertices=%d", gridSize, numGridVertices);
    gridVertices=calloc(2*numGridVertices,sizeof(GLfloat));
    texCoords=calloc(6*2*(gridSize-1)*(gridSize-1),sizeof(GLfloat));
    texVertices=calloc(6*2*(gridSize-1)*(gridSize-1),sizeof(GLfloat));
    self.motionManager=[[CMMotionManager alloc] init];
    _motionManager.deviceMotionUpdateInterval=0.02;   // 50 Hz
    _accelSwitch.enabled=_motionManager.isDeviceMotionAvailable;
    [self accelToggleAction:_accelSwitch];
    [self setupPhysicsInFrame:self.testView.frame];
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
        [masterViewController performSegueWithIdentifier:@"clothTestSegue" sender:nil];
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
    free(gridVertices);
    free(texCoords);
    free(texVertices);
}

@end

