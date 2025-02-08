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

	#if PRESET == 0
		vec3 compare = BSC(glcolor.rgb, 4.0, 1.0, 1.0);
		if ((((compare.r + compare.b)/2)/compare.g) < 0.8){
			vec3 tintcolor = vec3(0.4, 0.8, 0.2);
			vec4 tint = vec4(tintcolor, glcolor.a);
			if (getLuminance(compare.rgb) > 1.25){
				tint.rgb = BSC(tint.rgb, 0.9, 0.675, 1.5);
			}else{
				tint.rgb = BSC(tint.rgb, 1.0, 0.925, 1.5);
			}
			color = texture(gtexture, texcoord) * tint;
			color.rgb = BSC(color.rgb, 1.0, 1.0, 0.8);
			color.rgb = BSC(color.rgb, FOLIAGE_BRIGHTNESS, FOLIAGE_SATURATION, FOLIAGE_CONTRAST);
		}else{
			color = texture(gtexture, texcoord) * glcolor;
		}
	#else
		color = texture(gtexture, texcoord) * glcolor;
		color.rgb = BSC(color.rgb, 1.0, 1.3, 1.0);
	#endif
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

	float mult = 1.0;
	mult *= encodedNormal.r;
	mult *= 1-encodedNormal.r;
	mult *= dot(encodedNormal.rgb, vec3(0,1,0));

	mult = clamp(mult*3+0.25, 0.5, 1.0);
	color.rgb *= mult;
	
	color.rgb *= clamp(pow(light.rgb, vec3(2)), 0.0, 1.0);
}