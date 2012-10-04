//
//  CMGLESKProgram.h
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

@interface CMGLESKProgram : NSObject {
    GLuint program;
}

@property (nonatomic, assign, readonly) GLuint program;

- (BOOL)loadProgramFromStringsVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader attributeNames:(NSArray *)attributeNames uniformNames:(NSArray *)uniformNames error:(NSError **)error;
- (BOOL)loadProgramFromFilesVertexShader:(NSString *)vertexShaderPath fragmentShader:(NSString *)fragmentShaderPath attributeNames:(NSArray *)attributeNames uniformNames:(NSArray *)uniformNames error:(NSError **)error;

- (int)indexOfAttribute:(NSString *)attributeName;
- (int)indexOfUniform:(NSString *)uniformName;

@end


#pragma mark - Error domain and codes

NSString * const CMGLESKProgramErrorDomain;

NSInteger const CMGLESKProgramCompileError;
NSInteger const CMGLESKProgramLinkError;
NSInteger const CMGLESKProgramInvalidError;
NSInteger const CMGLESKProgramFileNotFound;
NSInteger const CMGLESKProgramAttributeNotFound;
NSInteger const CMGLESKProgramUniformNotFound;
