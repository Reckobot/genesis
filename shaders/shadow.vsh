#version 330 compatibility
#include "/lib/common.glsl"

out vec2 texcoord;

flat out int isGrass;

in vec2 mc_Entity;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	gl_Position.xyz = distortShadowClipPos(gl_Position.xyz);

	if (mc_Entity.x == 102){
		isGrass = 1;
	}else{
		isGrass = 0;
	}
}