//
//  CMGLESKUtil.m
//  CM GL ES Kit
//
//  Created by Chris Miles 2012.
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

#import "CMGLESKUtil.h"


void orthoMatrix(GLfloat *matrix, float left, float right, float bottom, float top, float zNear, float zFar)
{
    matrix[ 0] = 2.0f / (right-left);
    matrix[ 1] = 0.0f;
    matrix[ 2] = 0.0f;
    matrix[ 3] = 0.0f;
    matrix[ 4] = 0.0f;
    matrix[ 5] = 2.0f / (top-bottom);
    matrix[ 6] = 0.0f;
    matrix[ 7] = 0.0f;
    matrix[ 8] = 0.0f;
    matrix[ 9] = 0.0f;
    matrix[10] = -2.0f / (zFar-zNear);
    matrix[11] = 0.0f;
    matrix[12] = -(right+left) / (right-left);
    matrix[13] = -(top+bottom) / (top-bottom);
    matrix[14] = -(zFar+zNear) / (zFar-zNear);
    matrix[15] = 1.0f;
}
