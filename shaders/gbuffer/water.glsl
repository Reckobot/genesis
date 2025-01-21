#version 330 compatibility
#include "/lib/common.glsl"

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D lightmap;
uniform sampler2D gtexture;
in vec3 normal;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

flat in int isWater;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 light;
layout(location = 2) out vec4 encodedNormal;

void main() {
	if (bool(isWater)){
		vec4 waterColor = vec4(vec3(0,0,1), 1);
		waterColor.rgb = BSC(waterColor.rgb, 6, 0.2, 1.0);
		color = texture(gtexture, texcoord) * waterColor;
		color.a = 0.75;
	}else{
		color = texture(gtexture, texcoord) * glcolor;
	}

	vec2 lmc = lmcoord;
	light = texture(lightmap, lmc);
	light.rgb = BSC(light.rgb, 0.7, 1.0, 4.0);
	light.rgb = vec3(increment(light.r, 1, 8), increment(light.g, 1, 8), increment(light.b, 1, 8));
	light.rgb = clamp(light.rgb, 0.045, 100.0);
	if (color.a < alphaTestRef) {
		discard;
	}
	color *= light;

	encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
}