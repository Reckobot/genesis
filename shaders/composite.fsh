#version 330 compatibility
#include "/lib/common.glsl"
#include "/lib/settings.glsl"
#include "/lib/distort.glsl"

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec3 getShadow(vec3 shadowScreenPos){
	vec4 shadowColor = texture(shadowcolor0, shadowScreenPos.xy);
	float transparentShadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r); // sample the shadow map containing everything
	if(transparentShadow == 1.0){
	return vec3(1.0);
	}
	float opaqueShadow = step(shadowScreenPos.z, texture(shadowtex1, shadowScreenPos.xy).r); // sample the shadow map containing only opaque stuff
	if(opaqueShadow == 0.0){
	return vec3(0.0);
	}
	return shadowColor.rgb * 2.0;
}

vec3 getSoftShadow(vec4 shadowClipPos, float bias){
	const float range = 1.0;
	const float increment = 0.5;

	float noise = IGN(texcoord, frameCounter, vec2(viewWidth, viewHeight));

	float theta = noise * radians(360.0);
	float cosTheta = cos(theta);
	float sinTheta = sin(theta);

	mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta);

	vec3 shadowAccum = vec3(0.0);
	int samples = 0;

	for(float x = -range; x <= range; x += increment){
		for (float y = -range; y <= range; y+= increment){
			vec2 offset = rotation * vec2(x, y) / shadowMapResolution;
			vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0);
      		offsetShadowClipPos.z -= bias;
      		offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz);
      		vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w;
      		vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
      		shadowAccum += getShadow(shadowScreenPos);
      		samples++;
    	}
  	}

  	return shadowAccum / float(samples);
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
	vec3 ftplPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 worldPos = ftplPos + cameraPosition;
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	vec3 shadow = getSoftShadow(shadowClipPos, clamp(exp(length(viewPos)/16)*SHADOW_RES*0.00000005, 0.001, 1.0));

	float NoL = dot(normal, worldLightVector);

	vec3 lightDir = worldLightVector;
	vec3 viewDir = mat3(gbufferModelViewInverse) * -normalize(projectAndDivide(gbufferProjectionInverse, vec3(texcoord.xy, 0) * 2.0 - 1.0));
	vec3 halfwayDir = normalize(lightDir + viewDir);
	float roughness = getRoughness(texcoord, depthtex1, depth);
	float fresnel = getFresnel(texture(colortex5, texcoord).g, viewDir, normal);
	float spec = pow(max(dot(normal, halfwayDir), 0.5), roughness)*shadow.r;
	float geometric = min(
		(2*dot(halfwayDir, normal)*dot(normal, viewDir))
		/
		dot(viewDir, halfwayDir),

		(2*dot(halfwayDir, normal)*dot(normal, lightDir))
		/
		dot(viewDir, halfwayDir)
		)
	;
	vec3 vnormal = mat3(gbufferModelView) * normal;

	color.rgb *= texture(colortex1, texcoord).rgb;

	#ifdef STANDARD_LIGHTING
		if ((depth < 1)&&(texture(colortex3, texcoord) == vec4(0))){
			float NoV = dot(normal, viewDir);
			vec3 brdfspecular = ((fresnel * spec * geometric * NoL)/(4*NoL*NoV)) * (sunlight*SUN_BRIGHTNESS);
			vec3 brdfdiffuse = color.rgb * ((NoL) * (sunlight*SUN_BRIGHTNESS));
			vec3 brdf = clamp(brdfspecular + brdfdiffuse, 0.1, 1.0);
			float timeDay = clamp(getLuminance(skyColor)*2, 0.05, 1.0);
			brdf *= timeDay;
			brdf += texture(colortex0, texcoord).rgb * (ambient*AMBIENT_BRIGHTNESS);

			color.rgb = brdf;
		}
	#else
		if ((depth < 1)&&(texture(colortex3, texcoord) == vec4(0))){
			if (depth != texture(depthtex1, texcoord).r){
				color.rgb *= clamp(getLuminance(normal)+0.6, 0.6, 1.0);
			}
		}
	#endif
}