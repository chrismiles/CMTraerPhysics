//
//  CMGLESKTexture.h
//  CM GL ES Kit
//
//  Created by Chris Miles 2011.
//  Copyright 2011-2012 Chris Miles. All rights reserved.
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
#import <OpenGLES/ES2/gl.h>

typedef struct {
    GLfloat x1;
    GLfloat y1;
    GLfloat x2;
    GLfloat y2;
} CMGLESKTexCoord;


@interface CMGLESKTexture : NSObject

@property (nonatomic, assign)	GLuint	glTextureName;
@property (nonatomic, assign)	CGSize	size;

+ (id)textureNamed:(NSString *)imageName;
+ (id)textureNamed:(NSString *)imageName invertYAxis:(BOOL)invertYAxis;

- (id)initWithImage:(UIImage *)image invertYAxis:(BOOL)invertYAxis;
- (BOOL)setupTextureFromImage:(UIImage *)image;
- (BOOL)setupTextureFromImage:(UIImage *)image invertYAxis:(BOOL)invertYAxis;

- (CMGLESKTexCoord)croppedTextureCoord:(CGRect)subRect;
- (void)generateMipmap;

@end
