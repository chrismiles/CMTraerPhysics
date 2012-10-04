//
//  CMGLESKTexture.m
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

#import "CMGLESKTexture.h"

@implementation CMGLESKTexture

@synthesize glTextureName;
@synthesize size;

+ (id)textureNamed:(NSString *)imageName
{
    return [self textureNamed:imageName invertYAxis:NO];
}

+ (id)textureNamed:(NSString *)imageName invertYAxis:(BOOL)invertYAxis
{
    UIImage *image = [UIImage imageNamed:imageName];
    if (nil == image) {
	return nil;
    }
    
    CMGLESKTexture *texture = [[[CMGLESKTexture alloc] initWithImage:image invertYAxis:invertYAxis] autorelease];
    return texture;
}

- (BOOL)setupTextureFromImage:(UIImage *)image
{
    return [self setupTextureFromImage:image invertYAxis:NO];
}

- (BOOL)setupTextureFromImage:(UIImage *)image invertYAxis:(BOOL)invertYAxis
{
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
	return NO;
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    GLubyte * textureData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef textureContext = CGBitmapContextCreate(textureData, width, height, 8, width*4, CGImageGetColorSpace(imageRef), kCGImageAlphaPremultipliedLast);
    if (invertYAxis) {
	CGContextTranslateCTM(textureContext, 0.0f, height);     // invert texture Y-axis
	CGContextScaleCTM(textureContext, 1.0f, -1.0f);
    }
    CGContextDrawImage(textureContext, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(textureContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    // Set up the texture state.
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); 
    
    // This is necessary for non-power-of-two textures
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    //    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    
    free(textureData);
    
    self.glTextureName = texName;
    self.size = CGSizeMake(width, height);
    
    return YES;    
}

- (CMGLESKTexCoord)croppedTextureCoord:(CGRect)subRect
{
    CMGLESKTexCoord texCoord;
    texCoord.x1 = CGRectGetMinX(subRect) / size.width;
    texCoord.y1 = CGRectGetMinY(subRect) / size.height;
    texCoord.x2 = CGRectGetMaxX(subRect) / size.width;
    texCoord.y2 = CGRectGetMaxY(subRect) / size.height;
    return texCoord;
}

- (void)generateMipmap
{
    glBindTexture(GL_TEXTURE_2D, self.glTextureName);
    glGenerateMipmap(GL_TEXTURE_2D);
}


#pragma mark - Object lifecycle

- (id)initWithImage:(UIImage *)image invertYAxis:(BOOL)invertYAxis
{
    self = [super init];
    if (self) {
	if (image) {
	    BOOL success = [self setupTextureFromImage:image invertYAxis:invertYAxis];
	    if (!success) {
		return nil;
	    }
	}
    }
    
    return self;
}

- (void)dealloc
{
    glDeleteTextures(1, &glTextureName);
    
    [super dealloc];
}

@end
