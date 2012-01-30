//
//  WonderwallLikeVertexShader.glsl
//  CMTPDemo
//
//  Created by Chris Miles on 15/11/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

uniform vec4 color;
uniform mat4 mvp;

attribute vec4 position;
attribute vec2 textureCoord;

varying vec4 colorVarying;
varying vec2 textureCoordOut;

void main()
{
    gl_Position = mvp * position;
    colorVarying = color;
    textureCoordOut = textureCoord; 
} 
