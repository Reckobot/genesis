#version 330 compatibility
#include "/lib/common.glsl"
#include "/lib/settings.glsl"

uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D lightmap;
uniform sampler2D gtexture;
in vec3 normal;
in mat3 tbnmatrix;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

flat in int isWater;

/* RENDERTARGETS: 0,1,2,5 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 light;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 encodedSpecular;

vec3 getnormalmap(vec2 texcoord){
	vec3 normalmap = texture(normals, texcoord).rgb;
	normalmap = normalmap * 2 - 1;
	return tbnmatrix * normalmap;
}

void main() {
	float brightness = 5;
	#if PRESET == 1
		brightness = 4;
	#endif
	if (bool(isWater)){
		vec4 waterColor = vec4(vec3(0,0,1), 1);
		waterColor.rgb = BSC(waterColor.rgb, brightness, 0.2, 1.0);
		color = texture(gtexture, texcoord) * waterColor;
		color.a = WATER_TRANSPARENCY;
		color.rgb = BSC(color.rgb, WATER_BRIGHTNESS, WATER_SATURATION, WATER_CONTRAST);
	}else{
		color = texture(gtexture, texcoord) * glcolor;
	}

	vec2 lmc = lmcoord;
	light = texture(lightmap, lmc);
	light.rgb = BSC(light.rgb, 0.8, 1.0, 2.0);
	light.rgb = clamp(light.rgb, 0.045, 1.0);
	if (color.a < alphaTestRef) {
		discard;
	}
	color *= light;

	encodedNormal = vec4(getnormalmap(texcoord) * 1 + 0.5, 1.0);
	encodedNormal.a = 1;
	encodedSpecular = vec4(1);
}