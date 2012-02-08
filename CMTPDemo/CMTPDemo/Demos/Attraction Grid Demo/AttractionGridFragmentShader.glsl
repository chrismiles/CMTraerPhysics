//
//  AttractionGridFragmentShader.glsl
//  CMTPDemo
//
//  Created by Chris Miles on 15/11/11.
//  Copyright (c) 2011 Chris Miles. All rights reserved.
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
