//
//  CMTPCommon.h
//  CMTraerPhysics
//
//  Created by Chris Miles 2011.
//  Copyright 2011 Chris Miles. All rights reserved.
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

typedef float CMTPFloat;


typedef struct {
    CMTPFloat x;
    CMTPFloat y;
    CMTPFloat z;
} CMTPVector3D;

static inline CMTPVector3D CMTPVector3DMake(CMTPFloat inX, CMTPFloat inY, CMTPFloat inZ)
{
    CMTPVector3D ret;
    ret.x = inX;
    ret.y = inY;
    ret.z = inZ;
    return ret;
}

static inline CMTPVector3D CMTPVector3DScaleBy(CMTPVector3D vector, CMTPFloat factor)
{
    CMTPVector3D ret;
    ret.x = vector.x * factor;
    ret.y = vector.y * factor;
    ret.z = vector.z * factor;
    return ret;
}

static inline CMTPFloat CMTPVector3DMagnitude(CMTPVector3D vector)
{
    return sqrtf((vector.x * vector.x) + (vector.y * vector.y) + (vector.z * vector.z)); 
}

static inline void CMTPVector3DNormalize(CMTPVector3D *vector)
{
    CMTPFloat vecMag = CMTPVector3DMagnitude(*vector);
    if ( vecMag == 0.0 )
    {
	vector->x = 1.0;
	vector->y = 0.0;
	vector->z = 0.0;
        return;
    }
    vector->x /= vecMag;
    vector->y /= vecMag;
    vector->z /= vecMag;
}

static inline void CMTPVector3DFlip(CMTPVector3D *vector)
{
    vector->x = -vector->x;
    vector->y = -vector->y;
    vector->z = -vector->z;
}

static inline CMTPVector3D CMTPVector3DMakeWithStartAndEndVectors(CMTPVector3D start, CMTPVector3D end)
{
    CMTPVector3D ret;
    ret.x = end.x - start.x;
    ret.y = end.y - start.y;
    ret.z = end.z - start.z;
    CMTPVector3DNormalize(&ret);
    return ret;
}

static inline CMTPFloat CMTPVector3DDistance(CMTPVector3D vector1, CMTPVector3D vector2)
{
    CMTPVector3D v = CMTPVector3DMakeWithStartAndEndVectors(vector1, vector2);
    return CMTPVector3DMagnitude(v);
}

static inline CMTPVector3D CMTPVector3DAdd(CMTPVector3D vector1, CMTPVector3D vector2)
{
    CMTPVector3D ret;
    ret.x = vector1.x + vector2.x;
    ret.y = vector1.y + vector2.y;
    ret.z = vector1.z + vector2.z;
    return ret;
}

static inline NSString *NSStringFromCMTPVector3D(CMTPVector3D vector)
{
    return [NSString stringWithFormat:@"{%f, %f, %f}", vector.x, vector.y, vector.z];
}
