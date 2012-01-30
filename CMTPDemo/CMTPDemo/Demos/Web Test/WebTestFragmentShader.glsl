//
//  AttractionGridFragmentShader.glsl
//  CMTPDemo
//
//  Created by Chris Miles on 15/11/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
