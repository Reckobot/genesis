#version 330 compatibility
#include "/lib/distort.glsl"

out vec2 texcoord;

void main() {
	gl_Position = ftransform();
	gl_Position.xyz = distortShadowClipPos(gl_Position.xyz);
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}