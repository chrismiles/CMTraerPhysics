//
//  CMTPDWonderwallLikeViewController.m
//  CMTPDemo
//
//  Created by Chris Miles on 10/01/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
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
#import "CMTPDWonderwallLikeViewController.h"
#import "CMTraerPhysics.h"
#import <QuartzCore/QuartzCore.h>

#define kVertexArraySize 420

typedef struct {
    BOOL shouldDraw;
    CGPoint p0;
    CGPoint p1;
    CGPoint p2;
    CGPoint p3;
} HighlightCell;

#pragma mark - Static Globals
// Static globals so revisiting same demo remembers control settings.
static BOOL viewedBefore;
static BOOL fullFrameRate;
static BOOL highlightEnabled;

#pragma mark - C Functions
static BOOL
doesIntersectOnBothSegments(CGPoint p1,CGPoint p2,CGPoint p3,CGPoint p4){
    // based on an algorithm by Paul Bourke
    // http://local.wasp.uwa.edu.au/~pbourke/geometry/lineline2d/
    
    CMTPFloat denom=(p4.y-p3.y)*(p2.x-p1.x)-(p4.x-p3.x)*(p2.y-p1.y);
    CMTPFloat num_a=(p4.x-p3.x)*(p1.y-p3.y)-(p4.y-p3.y)*(p1.x-p3.x);
    CMTPFloat num_b=(p2.x-p1.x)*(p1.y-p3.y)-(p2.y-p1.y)*(p1.x-p3.x);
    if (denom==0) {
        return NO; //lines are parallel
    } else {
        CMTPFloat ua=num_a/denom;
        CMTPFloat ub=num_b/denom;
        if (ua==denom&&ub==denom) {
            return NO; //lines are coincident
        } else {
            //var intersect:Point = new Point(p1.x + ua*(p2.x - p1.x), p1.y + ua*(p2.y - p1.y));
            if (ub>=0&&ub<=1&&ua>=0&&ua<=1) {
                return YES;
            } else {
                return NO;
            }
        }
        //NOTE: if (ua >= 0 && ua <=1 && ub >= 0 && ub <= 1) then intersection lies within both segments
        //if only ua lies between 0 and 1, then intersection is within segment p1,p2
        //if only ub lies between 0 and 1, then intersection is within segment p3,p4
    }
}

#pragma mark - CMTPDWonderwallLikeViewController

@interface CMTPDWonderwallLikeViewController () {
    BOOL animating;

    CMTPFloat contentScale;
    CMTPFloat frameHeight,frameWidth;
    NSInteger animationFrameInterval;

    int textureCoordAttrib;
    int vertexAttrib;

    GLfloat* texCoords;
    GLfloat* vertices;

    HighlightCell highlightCell;
    GLfloat projectionMatrix[16];
    NSUInteger vertexArraySize;

    BOOL touching;
    CGPoint touchLocation;

    // FPS
    double fps_prev_time;
    NSUInteger fps_count;

    NSUInteger num_cols;
    NSUInteger num_rows;
    CMTPFloat cell_width;
    CMTPFloat cell_height;

    CMTPFloat sx;
    CMTPFloat sy;

    NSUInteger subdivisions;
}

// Physics
@property (strong,nonatomic) CMTPParticle* attractor;
@property (strong,nonatomic) NSMutableArray* particlesFixed;
@property (strong,nonatomic) NSMutableArray* particlesFree;
@property (strong,nonatomic) CMTPParticleSystem* s;

@property (strong,nonatomic) CADisplayLink* displayLink;
@property (strong,nonatomic) CMGLESKTexture* gridTexture;
@property (strong,nonatomic) CMGLESKProgram* shaderProgram;
@property (strong,nonatomic) NSDictionary* textureAtlasFrames;

@end

@implementation CMTPDWonderwallLikeViewController

#pragma mark - Touch location logic

-(BOOL)isMouseOnGrid {
    CGPoint _mp=touchLocation;
    CGPoint _o=CGPointMake(-400,-400);
    NSUInteger numIntersect;
    NSUInteger count=[_particlesFree count];
    for (NSUInteger i=0;i<count-1;i++) {
        NSArray* particlesFreeRow=[_particlesFree objectAtIndex:i];
        NSArray* particlesFreeRow1=[_particlesFree objectAtIndex:i+1];
        NSUInteger pfree_row_count=[particlesFreeRow count];
        for (NSUInteger j=0;j<pfree_row_count-1;j++) {
            CMTPParticle* pFreeij=[particlesFreeRow objectAtIndex:j];   // top / left
            CMTPParticle* pFreeij1=[particlesFreeRow objectAtIndex:j+1]; // top / right
            CMTPParticle* pFreei1j=[particlesFreeRow1 objectAtIndex:j]; // bottom / left
            CMTPParticle* pFreei1j1=[particlesFreeRow1 objectAtIndex:j+1];  // bottom / right

            CGPoint q0=CGPointMake(pFreeij.position.x,pFreeij.position.y);
            CGPoint q1=CGPointMake(pFreeij1.position.x,pFreeij1.position.y);
            CGPoint q2=CGPointMake(pFreei1j1.position.x,pFreei1j1.position.y);
            CGPoint q3=CGPointMake(pFreei1j.position.x,pFreei1j.position.y);

            numIntersect=0;
            if (doesIntersectOnBothSegments(_mp,_o,q0,q1)) {
                numIntersect++;
            }
            if (doesIntersectOnBothSegments(_mp,_o,q1,q2)) {
                numIntersect++;
            }
            if (doesIntersectOnBothSegments(_mp,_o,q2,q3)) {
                numIntersect++;
            }
            if (doesIntersectOnBothSegments(_mp,_o,q3,q0)) {
                numIntersect++;
            }
            if (numIntersect==1||numIntersect==3) {
                highlightCell.shouldDraw=YES;
                highlightCell.p0=q0;
                highlightCell.p1=q1;
                highlightCell.p2=q2;
                highlightCell.p3=q3;
                return YES;
            } else {
                highlightCell.shouldDraw=NO;
            }
        }
    }
    return NO;
}

#pragma mark - Full Frame Rate Control

-(void)enableFullFrameRate {
    _fullFrameRateLabel.hidden=NO;
    fullFrameRate=YES;
}

-(void)disableFullFrameRate {
    _fullFrameRateLabel.hidden=YES;
    fullFrameRate=NO;
    [self startAnimation];
}

#pragma mark - UIControl actions

-(IBAction)fullFrameRateAction:(id)sender {
    UISwitch* sw=(UISwitch*)sender;
    if (sw.on) {
        [self enableFullFrameRate];
    } else {
        [self disableFullFrameRate];
    }
}

-(IBAction)highlightToggleAction:(id)sender {
    UISwitch* sw=(UISwitch*)sender;
    highlightEnabled=sw.on;
}

#pragma mark - Setup

-(void)setupPhysicsInFrame:(CGRect)frame {
    num_cols=5;
    num_rows=7;

    CMTPFloat attractionStrength;
    CMTPFloat attractionMinDistance;
    if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
        // iPad
        attractionStrength=-56800;
        attractionMinDistance=110;
    } else {
        // iPhone
        attractionStrength=-3500;
        attractionMinDistance=35;
    }
    attractionStrength*=contentScale;
    attractionMinDistance*=contentScale;

    cell_width=CGRectGetWidth(frame)*0.8f/num_cols;
    cell_height=CGRectGetHeight(frame)*0.8f/num_rows;
    sx=CGRectGetWidth(frame)*0.1f;
    sy=CGRectGetHeight(frame)*0.1f;

    DLog(@"grid cell width, height: %f, %f",cell_width,cell_height);

    subdivisions=6;   // # of subdivisions to minimize distortion (per grid cell)

    vertexArraySize=kVertexArraySize*subdivisions*subdivisions;

    texCoords=calloc(vertexArraySize,sizeof(GLfloat));
    vertices=calloc(vertexArraySize,sizeof(GLfloat));

    self.particlesFixed=[[NSMutableArray alloc] init];
    self.particlesFree=[[NSMutableArray alloc] init];

    CMTPVector3D gravityVector=CMTPVector3DMake(0.0f,0.0f,0.0f);
    self.s=[[CMTPParticleSystem alloc] initWithGravityVector:gravityVector drag:0.1f];

    self.attractor=[_s makeParticleWithMass:1.0f position:CMTPVector3DMake(0.0f,0.0f,0.0f)];
    [_attractor makeFixed];
    for (NSUInteger i=0;i<=num_rows;i++) {
        NSMutableArray* row_particles_fixed=[[NSMutableArray alloc] init];
        NSMutableArray* row_particles_free=[[NSMutableArray alloc] init];
        for (NSUInteger j=0;j<=num_cols;j++) {
            CMTPParticle* a=[_s makeParticleWithMass:0.8f position:CMTPVector3DMake(sx+(j*cell_width),sy+(i*cell_height),0)];
            [a makeFixed];
            CMTPParticle* b=[_s makeParticleWithMass:0.8f position:CMTPVector3DMake(sx+(j*cell_width),sy+(i*cell_height),0)];
            [row_particles_fixed addObject:a];
            [row_particles_free addObject:b];
            [_s makeSpringBetweenParticleA:a particleB:b springConstant:0.017f damping:0.6f restLength:0.0f];
            [_s makeAttractionBetweenParticleA:_attractor particleB:b strength:attractionStrength minDistance:attractionMinDistance];
        }
        [_particlesFixed addObject:row_particles_fixed];
        [_particlesFree addObject:row_particles_free];
    }
}

#pragma mark - OpenGL rendering

-(NSString*)scaledImageName:(NSString*)imageName {
    NSString* result;
    if (contentScale>1.0f||UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
        // Choose hi-res (@2x) images for Retina and iPad displays
        NSString* name=[imageName stringByDeletingPathExtension];
        NSString* extension=[imageName pathExtension];
        result=[NSString stringWithFormat:@"%@@2x.%@",name,extension];
    } else {
        result=imageName;
    }
    return result;
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
    NSArray* uniformNames=[NSArray arrayWithObjects:@"color",@"enableTexture",@"mvp",@"sampler",nil];
    self.shaderProgram=[[CMGLESKProgram alloc] init];
    if (![_shaderProgram loadProgramFromFilesVertexShader:@"WonderwallLikeVertexShader.glsl" fragmentShader:@"WonderwallLikeFragmentShader.glsl" attributeNames:attributeNames uniformNames:uniformNames error:&error]) {
        ALog(@"Shader program load failed: %@",error);
    }
    ASSERT_GL_OK();

    textureCoordAttrib=[_shaderProgram indexOfAttribute:@"textureCoord"];
    vertexAttrib=[_shaderProgram indexOfAttribute:@"position"];

    /* Texture Atlas */
    NSString* atlasName=[self scaledImageName:@"wonderwall_atlas.plist"];
    NSDictionary* sceneAtlas1=[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[atlasName stringByDeletingPathExtension] ofType:[atlasName pathExtension]]];
    ZAssert(sceneAtlas1!=nil,@"Cannot find \"%@\"",atlasName);
    self.textureAtlasFrames=[sceneAtlas1 valueForKey:@"frames"];
    self.gridTexture=[CMGLESKTexture textureNamed:[self scaledImageName:@"wonderwall_atlas.png"]];
    ASSERT_GL_OK();
    [_gridTexture generateMipmap];
    ASSERT_GL_OK();

    glBindTexture(GL_TEXTURE_2D,_gridTexture.glTextureName);
    ASSERT_GL_OK();
}

-(void)drawFrame:(id)sender {
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
    /* *** Wonderwall Like **** */

    [_s tick:2.9f];
    if (!touching||![self isMouseOnGrid]) {
        _attractor.position=CMTPVector3DMake(-50000,-50000,0);
    } else {
        _attractor.position=CMTPVector3DMake(touchLocation.x,touchLocation.y,0);
    }
    if (fullFrameRate) {
        // Simulate at full frame rate; skip rendering as there's nothing to draw
        if (animating) {
            [self stopAnimation];
        }
        [self performSelector:@selector(drawFrame:) withObject:nil afterDelay:0.0];
        return;
    }
    /* GL rendering */

    [_testView setFramebuffer];

    glClearColor(0.5f,0.5f,0.5f,1.0f);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    glUseProgram(_shaderProgram.program);
    ASSERT_GL_OK();

    int uniformMVP=[_shaderProgram indexOfUniform:@"mvp"];
    glUniformMatrix4fv(uniformMVP,1,GL_FALSE,projectionMatrix);
    ASSERT_GL_OK();

    BOOL showImages=YES;
    if (showImages) {
        NSUInteger tIndex=0;
        NSUInteger vIndex=0;
        NSUInteger gridIndex=0;

        NSUInteger pfree_count=[_particlesFree count];
        for (NSUInteger i=0;i<pfree_count-1;i++) {
            NSArray* particlesFreeRow=[_particlesFree objectAtIndex:i];
            NSArray* particlesFreeRow1=[_particlesFree objectAtIndex:i+1];
            NSUInteger pfree_row_count=[particlesFreeRow count];
            for (NSUInteger j=0;j<pfree_row_count-1;j++) {
                NSArray* textureNames=[_textureAtlasFrames allKeys];
                NSString* textureName=[textureNames objectAtIndex:(gridIndex++%[textureNames count])];
                NSDictionary* textureData=[_textureAtlasFrames objectForKey:textureName];
                CGRect textureFrame=CGRectFromString([textureData valueForKey:@"textureRect"]);
                CMGLESKTexCoord texCoord=[_gridTexture croppedTextureCoord:textureFrame];

                CMTPParticle* pFreeij=[particlesFreeRow objectAtIndex:j]; // top / left
                CMTPParticle* pFreeij1=[particlesFreeRow objectAtIndex:j+1]; // top / right
                CMTPParticle* pFreei1j=[particlesFreeRow1 objectAtIndex:j]; // bottom / left
                CMTPParticle* pFreei1j1=[particlesFreeRow1 objectAtIndex:j+1];// bottom / right
                for (NSUInteger m=0;m<subdivisions;m++) {
                    CMTPFloat y_part=(CMTPFloat)m/(CMTPFloat)subdivisions;
                    CMTPFloat y_part1=(CMTPFloat)(m+1)/(CMTPFloat)subdivisions;

                    CMTPFloat x_lhs=pFreeij.position.x+y_part*(pFreei1j.position.x-pFreeij.position.x);
                    CMTPFloat x_lhs1=pFreeij.position.x+y_part1*(pFreei1j.position.x-pFreeij.position.x);
                    CMTPFloat x_rhs=pFreeij1.position.x+y_part*(pFreei1j1.position.x-pFreeij1.position.x);
                    CMTPFloat x_rhs1=pFreeij1.position.x+y_part1*(pFreei1j1.position.x-pFreeij1.position.x);
                    for (NSUInteger n=0;n<subdivisions;n++) {
                        CMTPFloat x_part=(CMTPFloat)n/(CMTPFloat)subdivisions;
                        CMTPFloat x_part1=(CMTPFloat)(n+1)/(CMTPFloat)subdivisions;

                        CMTPFloat y_top=pFreeij.position.y+x_part*(pFreeij1.position.y-pFreeij.position.y);
                        CMTPFloat y_top1=pFreeij.position.y+x_part1*(pFreeij1.position.y-pFreeij.position.y);
                        CMTPFloat y_bot=pFreei1j.position.y+x_part*(pFreei1j1.position.y-pFreei1j.position.y);
                        CMTPFloat y_bot1=pFreei1j.position.y+x_part1*(pFreei1j1.position.y-pFreei1j.position.y);

                        CGPoint p_tl=CGPointMake((x_lhs+x_part*(x_rhs-x_lhs))*contentScale,
                            (y_top+y_part*(y_bot-y_top))*contentScale);
                        CGPoint p_tr=CGPointMake((x_lhs+x_part1*(x_rhs-x_lhs))*contentScale,
                            (y_top1+y_part*(y_bot1-y_top1))*contentScale);
                        CGPoint p_bl=CGPointMake((x_lhs1+x_part*(x_rhs1-x_lhs1))*contentScale,
                            (y_top+y_part1*(y_bot-y_top))*contentScale);
                        CGPoint p_br=CGPointMake((x_lhs1+x_part1*(x_rhs1-x_lhs1))*contentScale,
                            (y_top1+y_part1*(y_bot1-y_top1))*contentScale);

                        CGPoint t_bl=CGPointMake(texCoord.x1+x_part*(texCoord.x2-texCoord.x1),texCoord.y1+y_part1*(texCoord.y2-texCoord.y1));
                        CGPoint t_br=CGPointMake(texCoord.x1+x_part1*(texCoord.x2-texCoord.x1),texCoord.y1+y_part1*(texCoord.y2-texCoord.y1));
                        CGPoint t_tl=CGPointMake(texCoord.x1+x_part*(texCoord.x2-texCoord.x1),texCoord.y1+y_part*(texCoord.y2-texCoord.y1));
                        CGPoint t_tr=CGPointMake(texCoord.x1+x_part1*(texCoord.x2-texCoord.x1),texCoord.y1+y_part*(texCoord.y2-texCoord.y1));

                        // Top left
                        vertices[vIndex++]=(GLfloat)p_tl.x;
                        vertices[vIndex++]=(GLfloat)p_tl.y;
                        texCoords[tIndex++]=(GLfloat)t_tl.x;
                        texCoords[tIndex++]=(GLfloat)t_tl.y;

                        // Bottom left
                        vertices[vIndex++]=(GLfloat)p_bl.x;
                        vertices[vIndex++]=(GLfloat)p_bl.y;
                        texCoords[tIndex++]=(GLfloat)t_bl.x;
                        texCoords[tIndex++]=(GLfloat)t_bl.y;

                        // Bottom right
                        vertices[vIndex++]=(GLfloat)p_br.x;
                        vertices[vIndex++]=(GLfloat)p_br.y;
                        texCoords[tIndex++]=(GLfloat)t_br.x;
                        texCoords[tIndex++]=(GLfloat)t_br.y;

                        // Top left
                        vertices[vIndex++]=(GLfloat)p_tl.x;
                        vertices[vIndex++]=(GLfloat)p_tl.y;
                        texCoords[tIndex++]=(GLfloat)t_tl.x;
                        texCoords[tIndex++]=(GLfloat)t_tl.y;

                        // Bottom right
                        vertices[vIndex++]=(GLfloat)p_br.x;
                        vertices[vIndex++]=(GLfloat)p_br.y;
                        texCoords[tIndex++]=(GLfloat)t_br.x;
                        texCoords[tIndex++]=(GLfloat)t_br.y;

                        // Top right
                        vertices[vIndex++]=(GLfloat)p_tr.x;
                        vertices[vIndex++]=(GLfloat)p_tr.y;
                        texCoords[tIndex++]=(GLfloat)t_tr.x;
                        texCoords[tIndex++]=(GLfloat)t_tr.y;
                    }
                }
            }
        }
        //DLog(@"vIndex=%d tIndex=%d", vIndex, tIndex);
        ZAssert(vIndex<=vertexArraySize,@"vIndex=%lu",(unsigned long)vIndex);
        ZAssert(tIndex<=vertexArraySize,@"tIndex=%lu",(unsigned long)tIndex);

        glUniform1i([_shaderProgram indexOfUniform:@"enableTexture"],GL_TRUE);

        int stride=0;
        glEnableVertexAttribArray((GLuint)vertexAttrib); // vertex coords
        glEnableVertexAttribArray((GLuint)textureCoordAttrib); // texture coords
        ASSERT_GL_OK();

        glVertexAttribPointer((GLuint)vertexAttrib,2,GL_FLOAT,GL_FALSE,stride,vertices);
        glVertexAttribPointer((GLuint)textureCoordAttrib,2,GL_FLOAT,GL_FALSE,stride,texCoords);
        glDrawArrays(GL_TRIANGLES,0,(GLsizei)(vIndex/2));

        glDisableVertexAttribArray((GLuint)vertexAttrib);
        glDisableVertexAttribArray((GLuint)textureCoordAttrib); // texture coords
    }
    if (highlightEnabled&&touching&&highlightCell.shouldDraw) {
        NSUInteger vIndex=0;

        glUniform1i([_shaderProgram indexOfUniform:@"enableTexture"],GL_FALSE);
        glUniform4f([_shaderProgram indexOfUniform:@"color"],1.0f,1.0f,1.0f,1.0f);
        ASSERT_GL_OK();

        int stride=0;
        glEnableVertexAttribArray((GLuint)vertexAttrib); // vertex coords
        ASSERT_GL_OK();

        vertices[vIndex++]=(GLfloat)(highlightCell.p1.x*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p1.y*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p2.x*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p2.y*contentScale);

        vertices[vIndex++]=(GLfloat)(highlightCell.p2.x*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p2.y*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p3.x*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p3.y*contentScale);

        vertices[vIndex++]=(GLfloat)(highlightCell.p3.x*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p3.y*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p0.x*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p0.y*contentScale);

        vertices[vIndex++]=(GLfloat)(highlightCell.p0.x*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p0.y*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p1.x*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p1.y*contentScale);

        vertices[vIndex++]=(GLfloat)(highlightCell.p1.x*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p1.y*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p3.x*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p3.y*contentScale);

        vertices[vIndex++]=(GLfloat)(highlightCell.p0.x*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p0.y*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p2.x*contentScale);
        vertices[vIndex++]=(GLfloat)(highlightCell.p2.y*contentScale);

        glVertexAttribPointer((GLuint)vertexAttrib,2,GL_FLOAT,GL_FALSE,stride,vertices);
        glDrawArrays((GLsizei)GL_LINES,0,(GLsizei)(vIndex/2));

        glDisableVertexAttribArray((GLuint)vertexAttrib);
    }
    [_testView.context presentRenderbuffer:GL_RENDERBUFFER];
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

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch* touch=[touches anyObject];
    touchLocation=[touch locationInView:self.testView];
    touching=YES;
}

-(void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch* touch=[touches anyObject];
    touchLocation=[touch locationInView:self.testView];
}

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    touching=NO;
}

-(void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
    touching=NO;
}

#pragma mark - View lifecycle

-(void)viewDidLoad {
    [super viewDidLoad];
    // Setting delegate here avoids seeing VC renamed to "Delegate" in IB.
    self.testView.delegate=self;
    if (!viewedBefore) {
        fullFrameRate=_fullFrameRateSwitch.on;
        highlightEnabled=_highlightSwitch.on;
        viewedBefore=YES;
    } else {
        _fullFrameRateSwitch.on=fullFrameRate;
        _highlightSwitch.on=highlightEnabled;
    };
    [self.navigationController setToolbarHidden:NO animated:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self physicsSetup];
    });
}

-(void)physicsSetup {
    contentScale=_testView.contentScaleFactor;
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
        [masterViewController performSegueWithIdentifier:@"wonderwallLikeSegue" sender:nil];
    }];
}

-(void)viewDidDisappear:(BOOL)animated {
    [self stopAnimation];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidDisappear:animated];
}

#pragma mark -

-(void)dealloc {
    // Tear down context.
    [_testView setContext:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    free(texCoords);
    free(vertices);
}

@end
