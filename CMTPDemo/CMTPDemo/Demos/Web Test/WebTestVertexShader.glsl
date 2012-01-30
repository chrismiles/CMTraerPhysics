//
//  AttractionGridVertexShader.glsl
//  CMTPDemo
//
//  Created by Chris Miles on 15/11/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

uniform vec4 color;
uniform mat4 mvp;

attribute vec4 position;
//attribute vec4 color;

varying vec4 colorVarying;

void main()
{
    gl_Position = mvp * position;
    colorVarying = color;
} 
