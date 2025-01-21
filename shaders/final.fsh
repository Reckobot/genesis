#version 330 compatibility
#include "/lib/common.glsl"
#include "/lib/settings.glsl"

uniform sampler2D depthtex0;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;

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

	#if RENDER_DISTANCE == 1 || RENDER_DISTANCE == 2
		if (doFog){
			if (texture(colortex3, texcoord) == vec4(0)){
				float dist = length(viewPos) / (64/renderdist*fogdensity);
				float fogFactor = exp(-4*fogdensity * (1.0 - dist));
				color.rgb = mix(color.rgb, fogcolor, clamp(fogFactor, 0.0, 1.0));
			}else{
				float dist = length(viewPos) / (64*3/renderdist*fogdensity);
				float fogFactor = exp(-4*fogdensity * (1.0 - dist));
				color.rgb = mix(color.rgb, fogcolor, clamp(fogFactor, 0.0, 1.0));
			}
		}
	#else
		fogcolor = alphaFogColor;
		fogcolor = BSC(fogcolor, getLuminance(skyColor)*1.5, 1.0, 1.0);
		fogdensity = 1.0;
		if (texture(colortex3, texcoord) == vec4(0)){
			float dist = length(viewPos) / (64/renderdist*fogdensity);
			float fogFactor = exp(-4*fogdensity * (1.0 - dist));
			color.rgb = mix(color.rgb, fogcolor, clamp(fogFactor, 0.0, 1.0));
		}else{
			float dist = length(viewPos) / (64*3/renderdist*fogdensity);
			float fogFactor = exp(-4*fogdensity * (1.0 - dist));
			color.rgb = mix(color.rgb, fogcolor, clamp(fogFactor, 0.0, 1.0));
		}
	#endif
}