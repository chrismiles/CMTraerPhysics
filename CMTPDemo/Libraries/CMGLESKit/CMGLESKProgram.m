//
//  CMGLESKProgram.m
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

#import "CMGLESKProgram.h"

NSString * const CMGLESKProgramErrorDomain = @"CMGLESKProgramErrorDomain";
NSInteger const CMGLESKProgramCompileError = 1;
NSInteger const CMGLESKProgramLinkError = 2;
NSInteger const CMGLESKProgramInvalidError = 3;
NSInteger const CMGLESKProgramFileNotFound = 4;
NSInteger const CMGLESKProgramAttributeNotFound = 5;
NSInteger const CMGLESKProgramUniformNotFound = 6;


@interface CMGLESKProgram ()
@property (nonatomic, assign, readwrite) GLuint program;

@property (strong, nonatomic) NSDictionary *attributeLocations;
@property (strong, nonatomic) NSDictionary *uniformLocations;

- (GLuint)compileShaderFromString:(NSString *)shader type:(GLenum)type error:(NSError **)error;
- (BOOL)linkProgramError:(NSError **)error;
@end


@implementation CMGLESKProgram

@synthesize attributeLocations, uniformLocations;
@synthesize program;


#pragma mark - Public methods

- (int)indexOfUniform:(NSString *)uniformName
{
    int index;
    NSNumber *location = [self.uniformLocations valueForKey:uniformName];
    ZAssert(location != nil, @"Location not found for uniform \"%@\"", uniformName);
    if (nil == location) {
        index = -1;
    }
    else {
        index = [location intValue];
    }
    return index;
}

- (int)indexOfAttribute:(NSString *)attributeName
{
    int index;
    NSNumber *location = [self.attributeLocations valueForKey:attributeName];
    ZAssert(location != nil, @"Location not found for attribute \"%@\"", attributeName);
    if (nil == location) {
        index = -1;
    }
    else {
        index = [location intValue];
    }
    return index;
}

- (BOOL)loadProgramFromStringsVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader attributeNames:(NSArray *)attributeNames uniformNames:(NSArray *)uniformNames error:(NSError **)error
{
    GLuint vertexShaderName, fragmentShaderName;
    
    program = glCreateProgram();
    
    vertexShaderName = [self compileShaderFromString:vertexShader type:GL_VERTEX_SHADER error:error];
    if (0 == vertexShaderName) {
        return NO;
    }
    
    fragmentShaderName = [self compileShaderFromString:fragmentShader type:GL_FRAGMENT_SHADER error:error];
    if (0 == fragmentShaderName) {
        return NO;
    }
    
    glAttachShader(program, vertexShaderName);
    glAttachShader(program, fragmentShaderName);
    
    if (![self linkProgramError:error]) {
        glDeleteShader(vertexShaderName);
        glDeleteShader(fragmentShaderName);
        glDeleteProgram(program);
        program = 0;
        
        return NO;
    }
    
    NSMutableDictionary *mutableAttributeLocations = [NSMutableDictionary dictionaryWithCapacity:[attributeNames count]];
    for (NSString *attributeName in attributeNames) {
        int attribLocation = glGetAttribLocation(program, (const GLchar *)[attributeName UTF8String]);
        if (-1 == attribLocation) {
            NSString *reason = [NSString stringWithFormat:@"Attribute location not found for \"%@\"", attributeName];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:reason forKey:@"reason"];
            if (error) {
                *error = [NSError errorWithDomain:CMGLESKProgramErrorDomain code:CMGLESKProgramAttributeNotFound userInfo:userInfo];
            }
            return NO;
        }
        [mutableAttributeLocations setValue:[NSNumber numberWithInt:attribLocation] forKey:attributeName];
    }
    self.attributeLocations = mutableAttributeLocations;
    
    NSMutableDictionary *mutableUniformLocations = [NSMutableDictionary dictionaryWithCapacity:[uniformNames count]];
    for (NSString *uniformName in uniformNames) {
        int uniformLocation = glGetUniformLocation(program, (const GLchar *)[uniformName UTF8String]);
        if (-1 == uniformLocation) {
            NSString *reason = [NSString stringWithFormat:@"Uniform location not found for \"%@\"", uniformName];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:reason forKey:@"reason"];
            if (error) {
                *error = [NSError errorWithDomain:CMGLESKProgramErrorDomain code:CMGLESKProgramUniformNotFound userInfo:userInfo];
            }
            return NO;
        }
        [mutableUniformLocations setValue:[NSNumber numberWithInt:uniformLocation] forKey:uniformName];
    }
    self.uniformLocations = mutableUniformLocations;
    
    glDeleteShader(vertexShaderName);
    glDeleteShader(fragmentShaderName);
    
    return YES;
}

- (BOOL)loadProgramFromFilesVertexShader:(NSString *)vertexShaderPath fragmentShader:(NSString *)fragmentShaderPath attributeNames:(NSArray *)attributeNames uniformNames:(NSArray *)uniformNames error:(NSError **)error
{
    NSString *vShaderFullPath = nil;
    NSString *fShaderFullPath = nil;
    
    // Determine full path of vertex shader file
    if ([vertexShaderPath hasPrefix:@"/"]) {
        vShaderFullPath = vertexShaderPath;
    }
    else {
        // Find absolute path in bundle
        vShaderFullPath = [[NSBundle mainBundle] pathForResource:[vertexShaderPath stringByDeletingPathExtension] ofType:[vertexShaderPath pathExtension]];
    }
    if (nil == vShaderFullPath) {
        NSString *reason = [NSString stringWithFormat:@"Vertex shader file not found \"%@\"", vertexShaderPath];
        if (error) {
            *error = [NSError errorWithDomain:CMGLESKProgramErrorDomain code:CMGLESKProgramFileNotFound userInfo:[NSDictionary dictionaryWithObject:reason forKey:@"reason"]];
        }
        return NO;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:vShaderFullPath]) {
        NSString *reason = [NSString stringWithFormat:@"Vertex shader file not found \"%@\"", vShaderFullPath];
        if (error) {
            *error = [NSError errorWithDomain:CMGLESKProgramErrorDomain code:CMGLESKProgramFileNotFound userInfo:[NSDictionary dictionaryWithObject:reason forKey:@"reason"]];
        }
        return NO;
    }
    
    // Determine full path of fragment shader file
    if ([fragmentShaderPath hasPrefix:@"/"]) {
        fShaderFullPath = fragmentShaderPath;
    }
    else {
        // Find absolute path in bundle
        fShaderFullPath = [[NSBundle mainBundle] pathForResource:[fragmentShaderPath stringByDeletingPathExtension] ofType:[fragmentShaderPath pathExtension]];
    }
    if (nil == fShaderFullPath) {
        NSString *reason = [NSString stringWithFormat:@"Fragment shader file not found \"%@\"", fragmentShaderPath];
        if (error) {
            *error = [NSError errorWithDomain:CMGLESKProgramErrorDomain code:CMGLESKProgramFileNotFound userInfo:[NSDictionary dictionaryWithObject:reason forKey:@"reason"]];
        }
        return NO;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:fShaderFullPath]) {
        NSString *reason = [NSString stringWithFormat:@"Fragment shader file not found \"%@\"", fShaderFullPath];
        if (error) {
            *error = [NSError errorWithDomain:CMGLESKProgramErrorDomain code:CMGLESKProgramFileNotFound userInfo:[NSDictionary dictionaryWithObject:reason forKey:@"reason"]];
        }
        return NO;
    }
    
    // Read contents of shaders
    
    NSString *vertexShader = [NSString stringWithContentsOfFile:vShaderFullPath encoding:NSUTF8StringEncoding error:error];
    if (*error) {
        return NO;
    }
    
    NSString *fragmentShader = [NSString stringWithContentsOfFile:fShaderFullPath encoding:NSUTF8StringEncoding error:error];
    if (*error) {
        return NO;
    }
    
    return [self loadProgramFromStringsVertexShader:vertexShader fragmentShader:fragmentShader attributeNames:attributeNames uniformNames:uniformNames error:error];
}

- (BOOL)validateProgramError:(NSError **)error
{
    GLint logLength, status;
    
    glValidateProgram(program);
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc((unsigned long)logLength);
        glGetProgramInfoLog(program, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(program, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        if (error) {
            *error = [NSError errorWithDomain:CMGLESKProgramErrorDomain code:CMGLESKProgramInvalidError userInfo:nil];
        }
        return NO;
    }
    
    return YES;
}


#pragma mark - Private methods

- (GLuint)compileShaderFromString:(NSString *)shader type:(GLenum)type error:(NSError **)error
{
    GLuint shaderName;
    GLint status;
    const GLchar *source;

    if (error) {
        *error = nil;
    }

    source = (GLchar *)[shader UTF8String];
    if (!source) {
        if (error) {
            *error = [NSError errorWithDomain:CMGLESKProgramErrorDomain code:CMGLESKProgramCompileError userInfo:nil];
        }
        return 0;
    }
    
    shaderName = glCreateShader(type);
    glShaderSource(shaderName, 1, &source, NULL);
    glCompileShader(shaderName);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(shaderName, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc((unsigned long)logLength);
        glGetShaderInfoLog(shaderName, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(shaderName, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(shaderName);
        if (error) {
            *error = [NSError errorWithDomain:CMGLESKProgramErrorDomain code:CMGLESKProgramCompileError userInfo:nil];
        }
        return 0;
    }
    
    return shaderName;
}

- (BOOL)linkProgramError:(NSError **)error
{
    GLint status;
    
    glLinkProgram(program);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc((unsigned long)logLength);
        glGetProgramInfoLog(program, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == 0) {
        if (error) {
            *error = [NSError errorWithDomain:CMGLESKProgramErrorDomain code:CMGLESKProgramLinkError userInfo:nil];
        }
        return NO;
    }
    
    return YES;
}

- (void)dealloc
{
    if (program) {
        glDeleteProgram(program);
        program = 0;
    }

    [attributeLocations release];
    [uniformLocations release];
    
    [super dealloc];
}

@end
