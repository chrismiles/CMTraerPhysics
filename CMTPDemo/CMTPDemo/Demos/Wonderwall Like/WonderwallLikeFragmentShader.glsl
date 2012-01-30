//
//  WonderwallLikeFragmentShader.glsl
//  CMTPDemo
//
//  Created by Chris Miles on 15/11/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

varying lowp vec4 colorVarying;
varying mediump vec2 textureCoordOut;

uniform bool enableTexture;
uniform sampler2D sampler;

void main()
{
    if (enableTexture) {
        // Texture sampling only
	gl_FragColor = texture2D(sampler, textureCoordOut);
    }
    else {
	gl_FragColor = colorVarying;
    }
}
