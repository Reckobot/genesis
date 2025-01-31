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
	float transparentShadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r);
	if(transparentShadow == 1.0){
		return vec3(1.0);
	}
	float opaqueShadow = step(shadowScreenPos.z, texture(shadowtex1, shadowScreenPos.xy).r);
	if(opaqueShadow == 0.0){
		return vec3(0.0);
	}
	vec4 shadowColor = texture(shadowcolor0, shadowScreenPos.xy);
	return shadowColor.rgb * (1.0 - shadowColor.a);
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
	shadowclipPos.z -= 0.005;
	vec3 shadowndcPos = shadowclipPos.rgb / shadowclipPos.w;
	vec3 shadowscreenPos = shadowndcPos * 0.5 + 0.5;

	vec3 shadow = vec3(0);
  	int samples = 0;

	float radius = 0.25;
	for(float x = -radius; x <= radius; x += 0.25){
	for (float y = -radius; y <= radius; y += 0.25){
		vec2 offset = vec2(x, y) / shadowMapResolution;
		vec4 offsetShadowClipPos = shadowclipPos + vec4(offset, 0.0, 0.0); // add offset
		offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
		vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w; // convert to NDC space
		vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
		shadow += getShadow(shadowScreenPos); // take shadow sample
		samples++;
	}
	}

	shadow /= samples;

	shadow *= dot(normal, worldLightVector)*2;

	shadow = clamp(shadow, clamp(exp(radius), 0.25, 0.5), 1.0);

	color.rgb *= texture(colortex1, texcoord).rgb;
	if ((depth < 1)&&(texture(colortex3, texcoord) == vec4(0))){
		color.rgb *= shadow;
	}
}