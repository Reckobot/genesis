#version 330 compatibility
#include "/lib/distort.glsl"

out vec2 texcoord;
out vec4 glcolor;

in vec2 mc_Entity;
flat out int isGrass;
flat out int isLeaves;

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
	gl_Position = ftransform();
	gl_Position.xyz = distortShadowClipPos(gl_Position.xyz);

	if (mc_Entity.x == 102){
		isGrass = 1;
	}else{
		isGrass = 0;
	}

	if (mc_Entity.x == 100){
		isLeaves = 1;
	}else{
		isLeaves = 0;
	}
}