//
//  AttractionGridFragmentShader.glsl
//  CMTPDemo
//
//  Created by Chris Miles on 15/11/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

varying lowp vec4 colorVarying;
varying mediump vec2 textureCoordOut;

uniform bool colorOnly;
uniform sampler2D sampler;

void main()
{
    //gl_FragColor = colorVarying;
    
    if (colorOnly) {
	gl_FragColor = colorVarying;
    }
    else {
        // Texture sampling only
	gl_FragColor = texture2D(sampler, textureCoordOut);
    }
//    else {
//        // Combine color with texture sampling
//	gl_FragColor = colorVarying * texture2D(sampler, textureCoordOut);
//    }
}
