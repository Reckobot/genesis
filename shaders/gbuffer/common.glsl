#version 330 compatibility
#include "/lib/common.glsl"
#include "/lib/settings.glsl"

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform vec4 entityColor;
in vec3 normal;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

flat in int isTintedAlpha;
in float tintSaturation;
flat in int isEntityShadow;
flat in int isLeaves;
flat in int isGrass;
flat in int isNonShaded;

/* RENDERTARGETS: 0,1,2,11 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 light;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 grass;

void main() {
	#if PRESET == 0
		if ((bool(isTintedAlpha))&&((glcolor.r + glcolor.g + glcolor.b)/3 < 0.9)){
			vec3 tintcolor = vec3(0.4, 0.8, 0.2);
			vec4 tint = vec4(tintcolor, glcolor.a);
			if (bool(isLeaves)){
				tint.rgb = BSC(tint.rgb, 1.7, (1-getLuminance(texture(gtexture, texcoord).rgb))*2.1*tintSaturation, 1.0);
			}else{
				tint.rgb = BSC(tint.rgb, 1.45, 0.865, 1.75);
			}
			color = texture(gtexture, texcoord) * tint;
			color.rgb = BSC(color.rgb, 1.0, 1.0, 0.8);
			color.rgb = BSC(color.rgb, FOLIAGE_BRIGHTNESS, FOLIAGE_SATURATION, FOLIAGE_CONTRAST);
			if (bool(isGrass)){
				color.rgb = BSC(color.rgb, 1.1, 0.5, 1.0);
			}
		}else{
			color = texture(gtexture, texcoord) * glcolor;
		}
	#else
		if (bool(isTintedAlpha)){
			color = texture(gtexture, texcoord) * vec4(BSC(glcolor.rgb, 1.0, 1.2, 1.0), 1);
			color.rgb = BSC(color.rgb, FOLIAGE_BRIGHTNESS, FOLIAGE_SATURATION, FOLIAGE_CONTRAST);
		}else{
			color = texture(gtexture, texcoord) * glcolor;
		}
	#endif
	vec2 lmc = lmcoord;
	light = texture(lightmap, lmc);

	float ambient;

	if (logicalHeightLimit == 384){
		ambient = 0.045;
	}else{
		ambient = 0.25;
	}

	if (light.r > 0.25){
		ambient = 0.25;
	}

	if (light.r < 0.985){
		light.rgb = pow(light.rgb, vec3(6));
	}else{
		light.rgb = vec3(1);
	}

	light.rgb = clamp(light.rgb, ambient, 1.0);
	#ifdef FAST_LEAVES
		if (bool(isLeaves)){
			if (color.a < alphaTestRef) {
				discard;
			}
		}else{
			if (color.a < alphaTestRef) {
				color.rgb *= 0.6;
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
	encodedNormal.a = 1;

	#ifdef INVISIBLE_GRASS
		if (bool(isGrass)){
			discard;
		}
	#endif

	if (bool(isNonShaded)||(bool(isGrass))){
		grass.rgb = vec3(1);
	}

	color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
}