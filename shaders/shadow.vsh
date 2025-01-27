#version 330 compatibility
#include "/lib/distort.glsl"
#include "/lib/settings.glsl"

out vec2 texcoord;
out vec4 glcolor;

flat out int isGrass;

in vec2 mc_Entity;

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;

	gl_Position = ftransform();
	gl_Position.xyz = distortShadowClipPos(gl_Position.xyz);

	isGrass = 0;
	#ifdef INVISIBLE_GRASS
		if (mc_Entity.x == 102){
			isGrass = 1;
		}
	#endif
}