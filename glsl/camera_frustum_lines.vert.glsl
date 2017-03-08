precision highp float;

attribute vec3 aPosition;

uniform mat4 uViewMVMatrix;
uniform mat4 uViewProjMatrix;

uniform mat4 uGeoCastMVMatrix;
uniform mat4 uGeoCastProjMatrix;
uniform mat4 uGeoCastMVMatrix_Inverse;
uniform mat4 uGeoCastProjMatrix_Inverse;
uniform vec2 uGeoCastClipRange;

void main(void) 
{
    gl_Position = uViewProjMatrix * uViewMVMatrix * (uGeoCastMVMatrix * uGeoCastProjMatrix_Inverse *  vec4(aPosition.xyz, 1.0));
}
