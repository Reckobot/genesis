#version 330 compatibility
#include "/lib/common.glsl"

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
in vec4 at_tangent;
out mat3 tbnmatrix;

flat out int isTintedAlpha;
flat out int isEntityShadow;
flat out int isLeaves;
flat out int isGrass;
out float tintSaturation;

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

	vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	vec3 bitangent = normalize(cross(tangent, normal) * at_tangent.w);
	tbnmatrix = mat3(mat3(gbufferModelViewInverse) * tangent, 
		mat3(gbufferModelViewInverse) * bitangent, 
		mat3(gbufferModelViewInverse) * normal
	);

	if ((mc_Entity.x >= 100)&&(mc_Entity.x <= 102)){
		isTintedAlpha = 1;
	}else{
		isTintedAlpha = 0;
	}

	if (mc_Entity.x == 101){
		tintSaturation = 1.0;
	}else{
		tintSaturation = 1.7;
	}

	if (mc_Entity.x != 100){
		isLeaves = 1;
	}else{
		isLeaves = 0;
	}

	if (mc_Entity.x == 102){
		isGrass = 1;
	}else{
		isGrass = 0;
	}
}