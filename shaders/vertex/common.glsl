#version 330 compatibility
#include "/lib/common.glsl"

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;

flat out int isTintedAlpha;
flat out int isEntityShadow;
flat out int isLeaves;
out float tintSaturation;
out float tintContrast;

uniform int entityId;

in vec2 mc_Entity;

void main() {
	gl_Position = ftransform();
	if (entityId == 100){
		isEntityShadow = 1;
	}else{
		isEntityShadow = 0;
	}
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
	normal = gl_NormalMatrix * gl_Normal;
	normal = mat3(gbufferModelViewInverse) * normal;

	if ((mc_Entity.x >= 100)&&(mc_Entity.x <= 102)){
		isTintedAlpha = 1;
	}else{
		isTintedAlpha = 0;
	}

	if (mc_Entity.x == 101){
		tintSaturation = 0.7;
		tintContrast = 1.2;
	}else{
		tintSaturation = 1.1;
		tintContrast = 1.0;
	}

	if (mc_Entity.x != 100){
		isLeaves = 1;
	}else{
		isLeaves = 0;
	}
}