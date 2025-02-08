#version 330 compatibility
#include "/lib/common.glsl"
#include "/lib/settings.glsl"

uniform sampler2D depthtex0;
uniform sampler2D lightmap;
uniform sampler2D gtexture;
in vec3 normal;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

flat in int isEntityShadow;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 light;
layout(location = 2) out vec4 encodedNormal;

void main() {
	float depth = texture(depthtex0, vec2(gl_FragCoord.xy)/vec2(viewWidth,viewHeight)).r;
	if (depth < 1){
		discard;
	}
	if (glcolor.b > 0.25){
		vec3 tintcolor = vec3(0.2,0.2,1)*0.95;
		vec4 tint = vec4(tintcolor, glcolor.a);
		color = texture(gtexture, texcoord) * tint;
	}else{
		color = texture(gtexture, texcoord) * glcolor;
	}
	vec2 lmc = lmcoord;
	light = texture(lightmap, lmc);

	float ambient;

	if (logicalHeightLimit == 384){
		ambient = 0.045;
	}else{
		ambient = 0.25;
	}

	light.rgb = clamp(light.rgb, ambient, 1.0);

	if (bool(isEntityShadow)){
		discard;
	}

	encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
	encodedNormal.a = 1;

	color.rgb *= clamp(pow(light.rgb, vec3(2)), 0.0, 1.0);
}