#version 330 compatibility
#include "/lib/common.glsl"
#include "/lib/distort.glsl"
#include "/lib/settings.glsl"

uniform mat4 shadowModelViewInverse;

uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec3 getShadow(vec3 shadowScreenPos){
	float shadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r);
	shadow += distance(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r)*50;
	shadow = clamp(shadow, 0.0, 1.0);
	return vec3(shadow);
}

vec3 getSoftShadow(vec4 shadowClipPos, float bias){
	vec3 shadowAccum = vec3(0.0);
	int samples = 0;

	float radius = 2;

	for(float x = -radius; x <= radius; x++){
		for (float y = -radius; y <= radius; y++){
			vec2 offset = vec2(x, y) / shadowMapResolution;
			vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0);
      		offsetShadowClipPos.z -= bias;
      		offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz);
      		vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w;
      		vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
      		shadowAccum += getShadow(shadowScreenPos);
      		samples++;
    	}
  	}

  	return shadowAccum / (samples);
}

void main() {
	color = texture(colortex0, texcoord);

	vec3 encodedNormal = texture(colortex2, texcoord).rgb;
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0);

	vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

	float depth = texture(depthtex0, texcoord).r;

	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 ftplPos = (gbufferModelViewInverse * vec4(viewPos, 1)).xyz;
	ftplPos += cameraPosition;
	ftplPos *= 16;
	ftplPos = vec3(ivec3(ftplPos));
	ftplPos /= 16;
	ftplPos -= cameraPosition;
	vec3 shadowviewPos = (shadowModelView * vec4(ftplPos, 1)).xyz;
	vec4 shadowclipPos = shadowProjection * vec4(shadowviewPos, 1);
	shadowclipPos.z -= 0.0025;
	vec4 shadowcPos = shadowclipPos;
	shadowclipPos.xyz = distortShadowClipPos(shadowclipPos.xyz);
	vec3 shadowndcPos = shadowclipPos.rgb / shadowclipPos.w;
	vec3 shadowscreenPos = shadowndcPos * 0.5 + 0.5;
	vec3 shadow = getSoftShadow(shadowcPos, clamp(exp(length(viewPos)/16)*shadowMapResolution*0.00000005, 0.001, 1.0));

	shadow *= dot(normal, worldLightVector)*2;

	shadow = clamp(shadow, 0.5, 1.0);

	color.rgb *= texture(colortex1, texcoord).rgb;
	if ((depth < 1)&&(texture(colortex3, texcoord) == vec4(0))){
		color.rgb *= shadow;
	}
}