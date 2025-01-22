#version 330 compatibility
#include "/lib/common.glsl"
#include "/lib/settings.glsl"

uniform sampler2D lightmap;
uniform sampler2D gtexture;
in vec3 normal;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

flat in int isTintedAlpha;
in float tintSaturation;
in float tintContrast;
flat in int isEntityShadow;
flat in int isLeaves;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 light;
layout(location = 2) out vec4 encodedNormal;

void main() {
	#if PRESET == 0
		if ((bool(isTintedAlpha))&&((((glcolor.r + glcolor.b)/2) - glcolor.g) <= -0.1)){
			vec3 tintcolor = vec3(0.27, 0.8, 0.2);
			vec4 tint = vec4(tintcolor, glcolor.a);
			color = texture(gtexture, texcoord) * tint;
			color.rgb = BSC(color.rgb, 1.6, tintSaturation, tintContrast);
		}else{
			color = texture(gtexture, texcoord) * glcolor;
		}
	#else
		if (bool(isTintedAlpha)){
			color = texture(gtexture, texcoord) * vec4(BSC(glcolor.rgb, 1.0, 1.2, 1.0), 1);
		}else{
			color = texture(gtexture, texcoord) * glcolor;
		}
	#endif
	vec2 lmc = lmcoord;
	light = texture(lightmap, lmc);
	light.rgb = BSC(light.rgb, 0.7, 0.0, 4.0);

	float ambient;

	if (logicalHeightLimit == 384){
		ambient = 0.045;
	}else{
		ambient = 0.25;
	}

	light.rgb = clamp(light.rgb, ambient, 1.0);
	#ifdef FAST_LEAVES
		if (bool(isLeaves)){
			if (color.a < alphaTestRef) {
				discard;
			}
		}else{
			if (color.a < alphaTestRef) {
				color.rgb *= 0.75;
			}
		}
	#else
		if (color.a < alphaTestRef) {
			discard;
		}
	#endif

	if (bool(isEntityShadow)){
		discard;
	}

	encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
}