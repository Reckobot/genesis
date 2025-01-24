#version 330 compatibility
#include "/lib/common.glsl"
#include "/lib/settings.glsl"
#include "/lib/tonemap.glsl"

uniform sampler2D depthtex0;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex6;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

    float depth = texture(depthtex0, texcoord).r;

	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 pos = screenToView(vec3(texcoord.xy, depth));

	vec3 fogcolor = calcSkyColor(normalize(pos));
	float fogdensity = 1.25;
	bool doFog = false;

	if ((depth < 1)){
		doFog = true;
	}

	if (isEyeInWater == 1){
		fogcolor = vec3(0.05,0.05,0.35);
		fogdensity = 0.25;
		doFog = true;
	}

	float renderdist;

	#if RENDER_DISTANCE == 1
		renderdist = 0.375;
	#elif RENDER_DISTANCE == 2
		renderdist = 0.5;
	#elif RENDER_DISTANCE == 3
		renderdist = 0.75;
	#elif RENDER_DISTANCE == 4
		renderdist = 2.25;
	#endif

	#ifdef TONEMAP
		if (depth < 1){
			color.rgb = aces(color.rgb);
			color.rgb = BSC(color.rgb, 1.0, 1.0, 1.2);
		}
	#endif

	#if RENDER_DISTANCE != 6 && RENDER_DISTANCE != 5
		#if RENDER_DISTANCE == 1 || RENDER_DISTANCE == 2
			if (doFog){
				float dist = length(viewPos) / (64/renderdist*fogdensity);
				float fogFactor = exp(-4*fogdensity * (1.0 - dist));
				color.rgb = mix(color.rgb, fogcolor, clamp(fogFactor, 0.0, 1.0));
			}
		#else
			fogcolor = alphaFogColor;
			fogcolor = BSC(fogcolor, getLuminance(skyColor)*1.5, 1.0, 1.0);
			fogdensity = 0.9;
			float dist = length(viewPos) / (64/renderdist*fogdensity);
			float fogFactor = exp(-4*fogdensity * (1.0 - dist));
			color.rgb = mix(color.rgb, fogcolor, clamp(fogFactor, 0.0, 1.0));
		#endif
	#elif RENDER_DISTANCE == 5
		if (doFog){
			float dist = length(viewPos) / (far);
			float fogFactor = exp(-4*fogdensity * (1.0 - dist));
			color.rgb = mix(color.rgb, fogcolor, clamp(fogFactor, 0.0, 1.0));
		}
	#endif

	color.rgb = BSC(color.rgb, BRIGHTNESS, SATURATION, CONTRAST);

	#ifdef WATERMARK
		ivec2 coord = ivec2(texcoord*vec2(viewWidth, viewHeight))/ivec2(WATERMARK_SCALE);
		coord.y = int(viewHeight/(WATERMARK_SCALE+0.005)) - coord.y;
		vec4 watermark = texelFetch(colortex6, coord, 0);
		color.rgb = mix(color.rgb, watermark.rgb, watermark.a);
	#endif
}