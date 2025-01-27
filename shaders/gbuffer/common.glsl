#version 330 compatibility
#include "/lib/common.glsl"
#include "/lib/settings.glsl"

uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D lightmap;
uniform sampler2D gtexture;
in vec3 normal;
in mat3 tbnmatrix;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

flat in int isTintedAlpha;
in float tintSaturation;
flat in int isEntityShadow;
flat in int isLeaves;
flat in int isGrass;

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
	#if PRESET == 0
		if ((bool(isTintedAlpha))&&((((glcolor.r + glcolor.b)/2) - glcolor.g) <= -0.1)){
			vec3 tintcolor = vec3(0.4, 0.8, 0.2);
			vec4 tint = vec4(tintcolor, glcolor.a);
			tint.rgb = BSC(tint.rgb, 1.7, (1-getLuminance(texture(gtexture, texcoord).rgb))*2.3*tintSaturation, 1.0);
			color = texture(gtexture, texcoord) * tint;
			color.rgb = BSC(color.rgb, 1.0, 1.0, 0.75);
			color.rgb = BSC(color.rgb, FOLIAGE_BRIGHTNESS, FOLIAGE_SATURATION, FOLIAGE_CONTRAST);
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
	light.rgb = BSC(light.rgb, 0.8, 0.0, 2.0);

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
				color.rgb *= 0.25;
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

	encodedNormal = vec4(getnormalmap(texcoord) * 1 + 0.5, 1.0);
	encodedSpecular = texture(specular, texcoord);
	
	encodedSpecular.a = 1;
	color.a = 1;

	#ifdef INVISIBLE_GRASS
		if (bool(isGrass)){
			discard;
		}
	#endif
}