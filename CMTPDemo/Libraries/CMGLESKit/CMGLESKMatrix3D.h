//
//  CMGLESKMatrix3D.h
//  CM GL ES Kit
//
//  Created by Chris Miles 2011.
//  Copyright (c) 2011-2012 Chris Miles. All rights reserved.
//
//  Some parts are copyright (c) 2007-2008 Wolfgang Engel and Matthias Grundmann.
//  Some parts are derived from code published by Jeff LaMarche.
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

#ifndef CMGLESKMatrix3D_h
#define CMGLESKMatrix3D_h

typedef GLfloat Matrix3D[16];

// OpenGL ES hardware accelerates Vector * Matrix but not Matrix * Matrix
/* 
 These defines, the fast sine function, and the vectorized version of the 
 matrix multiply function below are based on the Matrix4Mul method from 
 the vfp-math-library. Thi code has been modified, and are subject to  
 the original license terms and ownership as follow:
 
 VFP math library for the iPhone / iPod touch
 
 Copyright (c) 2007-2008 Wolfgang Engel and Matthias Grundmann
 http://code.google.com/p/vfpmathlibrary/
 
 This software is provided 'as-is', without any express or implied warranty.
 In no event will the authors be held liable for any damages arising
 from the use of this software.
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it freely,
 subject to the following restrictions:
 
 1. The origin of this software must not be misrepresented; you must
 not claim that you wrote the original software. If you use this
 software in a product, an acknowledgment in the product documentation
 would be appreciated but is not required.
 
 2. Altered source versions must be plainly marked as such, and must
 not be misrepresented as being the original software.
 
 3. This notice may not be removed or altered from any source distribution.
 */
static inline float fastAbs(float x) { return (x < 0) ? -x : x; }
static inline GLfloat fastSinf(GLfloat x)
{
    // fast sin function; maximum error is 0.001
    const float P = 0.225f;
    
    x = x * (float)M_1_PI;
    int k = (int) round(x);
    x = x - k;
    
    float y = (4 - 4 * fastAbs(x)) * x;
    
    y = P * (y * fastAbs(y) - y) + y;
    
    return (k&1) ? -y : y;
}

#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
#define VFP_CLOBBER_S0_S31 "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8",  \
"s9", "s10", "s11", "s12", "s13", "s14", "s15", "s16",  \
"s17", "s18", "s19", "s20", "s21", "s22", "s23", "s24",  \
"s25", "s26", "s27", "s28", "s29", "s30", "s31"
#define VFP_VECTOR_LENGTH(VEC_LENGTH) "fmrx    r0, fpscr                         \n\t" \
"bic     r0, r0, #0x00370000               \n\t" \
"orr     r0, r0, #0x000" #VEC_LENGTH "0000 \n\t" \
"fmxr    fpscr, r0                         \n\t"
#define VFP_VECTOR_LENGTH_ZERO "fmrx    r0, fpscr            \n\t" \
"bic     r0, r0, #0x00370000  \n\t" \
"fmxr    fpscr, r0            \n\t" 
#endif
static inline void Matrix3DMultiply(Matrix3D m1, Matrix3D m2, Matrix3D result)
{
#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
    __asm__ __volatile__ ( VFP_VECTOR_LENGTH(3)
                          
                          // Interleaving loads and adds/muls for faster calculation.
                          // Let A:=src_ptr_1, B:=src_ptr_2, then
                          // function computes A*B as (B^T * A^T)^T.
                          
                          // Load the whole matrix into memory.
                          "VLDMIA.32  %2, {s8-s23}    \n\t"
                          // Load first column to scalar bank.
                          "VLDMIA.32  %1!, {s0-s3}    \n\t"
                          // First column times matrix.
                          "fmuls s24, s8, s0        \n\t"
                          "fmacs s24, s12, s1       \n\t"
                          
                          // Load second column to scalar bank.
                          "VLDMIA.32 %1!,  {s4-s7}    \n\t"
                          
                          "fmacs s24, s16, s2       \n\t"
                          "fmacs s24, s20, s3       \n\t"
                          // Save first column.
                          "VSTMIA.32  %0!, {s24-s27}  \n\t"
                          
                          // Second column times matrix.
                          "fmuls s28, s8, s4        \n\t"
                          "fmacs s28, s12, s5       \n\t"
                          
                          // Load third column to scalar bank.
                          "VLDMIA.32  %1!, {s0-s3}    \n\t"
                          
                          "fmacs s28, s16, s6       \n\t"
                          "fmacs s28, s20, s7       \n\t"
                          // Save second column.
                          "VSTMIA.32  %0!, {s28-s31}  \n\t"
                          
                          // Third column times matrix.
                          "fmuls s24, s8, s0        \n\t"
                          "fmacs s24, s12, s1       \n\t"
                          
                          // Load fourth column to scalar bank.
                          "VLDMIA.32 %1,  {s4-s7}    \n\t"
                          
                          "fmacs s24, s16, s2       \n\t"
                          "fmacs s24, s20, s3       \n\t"
                          // Save third column.
                          "VSTMIA.32  %0!, {s24-s27}  \n\t"
                          
                          // Fourth column times matrix.
                          "fmuls s28, s8, s4        \n\t"
                          "fmacs s28, s12, s5       \n\t"
                          "fmacs s28, s16, s6       \n\t"
                          "fmacs s28, s20, s7       \n\t"
                          // Save fourth column.
                          "VSTMIA.32  %0!, {s28-s31}  \n\t" 
                          
                          VFP_VECTOR_LENGTH_ZERO
                          : "=r" (result), "=r" (m2)
                          : "r" (m1), "0" (result), "1" (m2)
                          : "r0", "cc", "memory", VFP_CLOBBER_S0_S31
                          );
#else
    result[0] = m1[0] * m2[0] + m1[4] * m2[1] + m1[8] * m2[2] + m1[12] * m2[3];
    result[1] = m1[1] * m2[0] + m1[5] * m2[1] + m1[9] * m2[2] + m1[13] * m2[3];
    result[2] = m1[2] * m2[0] + m1[6] * m2[1] + m1[10] * m2[2] + m1[14] * m2[3];
    result[3] = m1[3] * m2[0] + m1[7] * m2[1] + m1[11] * m2[2] + m1[15] * m2[3];
    
    result[4] = m1[0] * m2[4] + m1[4] * m2[5] + m1[8] * m2[6] + m1[12] * m2[7];
    result[5] = m1[1] * m2[4] + m1[5] * m2[5] + m1[9] * m2[6] + m1[13] * m2[7];
    result[6] = m1[2] * m2[4] + m1[6] * m2[5] + m1[10] * m2[6] + m1[14] * m2[7];
    result[7] = m1[3] * m2[4] + m1[7] * m2[5] + m1[11] * m2[6] + m1[15] * m2[7];
    
    result[8] = m1[0] * m2[8] + m1[4] * m2[9] + m1[8] * m2[10] + m1[12] * m2[11];
    result[9] = m1[1] * m2[8] + m1[5] * m2[9] + m1[9] * m2[10] + m1[13] * m2[11];
    result[10] = m1[2] * m2[8] + m1[6] * m2[9] + m1[10] * m2[10] + m1[14] * m2[11];
    result[11] = m1[3] * m2[8] + m1[7] * m2[9] + m1[11] * m2[10] + m1[15] * m2[11];
    
    result[12] = m1[0] * m2[12] + m1[4] * m2[13] + m1[8] * m2[14] + m1[12] * m2[15];
    result[13] = m1[1] * m2[12] + m1[5] * m2[13] + m1[9] * m2[14] + m1[13] * m2[15];
    result[14] = m1[2] * m2[12] + m1[6] * m2[13] + m1[10] * m2[14] + m1[14] * m2[15];
    result[15] = m1[3] * m2[12] + m1[7] * m2[13] + m1[11] * m2[14] + m1[15] * m2[15];
#endif
    
}

/*
 * Some Matrix3D functions below are based on code published by Jeff LaMarche.
 */

static inline void Matrix3DSetIdentity(Matrix3D matrix)
{
    matrix[0] = matrix[5] = matrix[10] = matrix[15] = 1.0;
    matrix[1] = matrix[2] = matrix[3] = matrix[4] = 0.0;
    matrix[6] = matrix[7] = matrix[8] = matrix[9] = 0.0;    
    matrix[11] = matrix[12] = matrix[13] = matrix[14] = 0.0;
}

static inline void Matrix3DSetTranslation(Matrix3D matrix, GLfloat xTranslate, GLfloat yTranslate, GLfloat zTranslate)
{
    matrix[0] = matrix[5] = matrix[10] = matrix[15] = 1.0;
    matrix[1] = matrix[2] = matrix[3] = matrix[4] = 0.0;
    matrix[6] = matrix[7] = matrix[8] = matrix[9] = 0.0;    
    matrix[11] = 0.0;
    matrix[12] = xTranslate;
    matrix[13] = yTranslate;
    matrix[14] = zTranslate;   
}

static inline void Matrix3DSetScaling(Matrix3D matrix, GLfloat xScale, GLfloat yScale, GLfloat zScale)
{
    matrix[1] = matrix[2] = matrix[3] = matrix[4] = 0.0;
    matrix[6] = matrix[7] = matrix[8] = matrix[9] = 0.0;
    matrix[11] = matrix[12] = matrix[13] = matrix[14] = 0.0;
    matrix[0] = xScale;
    matrix[5] = yScale;
    matrix[10] = zScale;
    matrix[15] = 1.0;
}

static inline void Matrix3DSetUniformScaling(Matrix3D matrix, GLfloat scale)
{
    Matrix3DSetScaling(matrix, scale, scale, scale);
}

static inline void Matrix3DSetXRotationUsingRadians(Matrix3D matrix, GLfloat degrees)
{
    matrix[0] = matrix[15] = 1.0;
    matrix[1] = matrix[2] = matrix[3] = matrix[4] = 0.0;
    matrix[7] = matrix[8] = 0.0;    
    matrix[11] = matrix[12] = matrix[13] = matrix[14] = 0.0;
    
    matrix[5] = cosf(degrees);
    matrix[6] = -fastSinf(degrees);
    matrix[9] = -matrix[6];
    matrix[10] = matrix[5];
}

static inline void Matrix3DSetXRotationUsingDegrees(Matrix3D matrix, GLfloat degrees)
{
    Matrix3DSetXRotationUsingRadians(matrix, degrees * (float)M_PI / 180.0f);
}

static inline void Matrix3DSetYRotationUsingRadians(Matrix3D matrix, GLfloat degrees)
{
    matrix[0] = cosf(degrees);
    matrix[2] = fastSinf(degrees);
    matrix[8] = -matrix[2];
    matrix[10] = matrix[0];
    matrix[1] = matrix[3] = matrix[4] = matrix[6] = matrix[7] = 0.0;
    matrix[9] = matrix[11] = matrix[13] = matrix[12] = matrix[14] = 0.0;
    matrix[5] = matrix[15] = 1.0;
}

static inline void Matrix3DSetYRotationUsingDegrees(Matrix3D matrix, GLfloat degrees)
{
    Matrix3DSetYRotationUsingRadians(matrix, degrees * (float)M_PI / 180.0f);
}

static inline void Matrix3DSetZRotationUsingRadians(Matrix3D matrix, GLfloat degrees)
{
    matrix[0] = cosf(degrees);
    matrix[1] = fastSinf(degrees);
    matrix[4] = -matrix[1];
    matrix[5] = matrix[0];
    matrix[2] = matrix[3] = matrix[6] = matrix[7] = matrix[8] = 0.0;
    matrix[9] = matrix[11] = matrix[12] = matrix[13] = matrix[14] = 0.0;
    matrix[10] = matrix[15] = 1.0;
}

static inline void Matrix3DSetZRotationUsingDegrees(Matrix3D matrix, GLfloat degrees)
{
    Matrix3DSetZRotationUsingRadians(matrix, degrees * (float)M_PI / 180.0f);
}

static inline void Matrix3DSetRotationByRadians(Matrix3D matrix, GLfloat angle, GLfloat x, GLfloat y, GLfloat z)
{
    GLfloat mag = sqrtf((x*x) + (y*y) + (z*z));
    if (mag == 0.0)
    {
        x = 1.0;
        y = 0.0;
        z = 0.0;
    }
    else if (mag != 1.0)
    {
        x /= mag;
        y /= mag;
        z /= mag;
    }
    
    GLfloat c = cosf(angle);
    GLfloat s = fastSinf(angle);
    matrix[3] = matrix[7] = matrix[11] = matrix[12] = matrix[13] = matrix[14] = 0.0;
    matrix[15] = 1.0;
    
    matrix[0] = (x*x)*(1-c) + c;
    matrix[1] = (y*x)*(1-c) + (z*s);
    matrix[2] = (x*z)*(1-c) - (y*s);
    matrix[4] = (x*y)*(1-c)-(z*s);
    matrix[5] = (y*y)*(1-c)+c;
    matrix[6] = (y*z)*(1-c)+(x*s);
    matrix[8] = (x*z)*(1-c)+(y*s);
    matrix[9] = (y*z)*(1-c)-(x*s);
    matrix[10] = (z*z)*(1-c)+c;
    
}

static inline void Matrix3DSetRotationByDegrees(Matrix3D matrix, GLfloat angle, GLfloat x, GLfloat y, GLfloat z)
{
    Matrix3DSetRotationByRadians(matrix, angle * (float)M_PI / 180.0f, x, y, z);
}

static inline void Matrix3DSetShear(Matrix3D matrix, GLfloat xShear, GLfloat yShear)
{
    matrix[0] = matrix[5] =  matrix[10] = matrix[15] = 1.0;
    matrix[1] = matrix[2] = matrix[3] = 0.0;
    matrix[6] = matrix[7] = matrix[8] = matrix[9] = 0.0;    
    matrix[11] = matrix[12] = matrix[13] = matrix[14] = 0.0;
    matrix[1] = xShear;
    matrix[4] = yShear;
}

static inline void Matrix3DSetFrustum(Matrix3D m, GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, GLfloat near, GLfloat far)
{
    GLfloat a = 2 * near / (right - left);
    GLfloat b = 2 * near / (top - bottom);
    GLfloat c = (right + left) / (right - left);
    GLfloat d = (top + bottom) / (top - bottom);
    GLfloat e = - (far + near) / (far - near);
    GLfloat f = -2 * far * near / (far - near);
    m[4*0+0] = a; m[4*0+1] = 0; m[4*0+2] = 0; m[4*0+3] = 0;
    m[4*1+0] = 0; m[4*1+1] = b; m[4*1+2] = 0; m[4*1+3] = 0;
    m[4*2+0] = c; m[4*2+1] = d; m[4*2+2] = e; m[4*2+3] = -1;
    m[4*3+0] = 0; m[4*3+1] = 0; m[4*3+2] = f; m[4*3+3] = 1;
}

#endif	/* CMGLESKMatrix3D_h */
