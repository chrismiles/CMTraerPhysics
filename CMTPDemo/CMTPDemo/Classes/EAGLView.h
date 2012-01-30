
//
//  EAGLView.h
//  CMTPDemo
//
//  Created by Chris Miles on 14/11/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@protocol EAGLViewDelegate;

@interface EAGLView : UIView {
@private
    EAGLContext *context;
    GLuint defaultFramebuffer, colorRenderbuffer, depthRenderbuffer;
}

@property (nonatomic, assign) IBOutlet id<EAGLViewDelegate> delegate;

@property (nonatomic, retain) EAGLContext *context;

@property (nonatomic, readonly) GLuint defaultFramebuffer;
@property (nonatomic, readonly) GLint framebufferWidth;
@property (nonatomic, readonly) GLint framebufferHeight;

- (void)setFramebuffer;

@end


@protocol EAGLViewDelegate <NSObject>

@optional
- (void)eaglView:(EAGLView *)eaglView framebufferCreatedWithSize:(CGSize)framebufferSize;

@end