#version 330 compatibility
#include "/lib/common.glsl"

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;

uniform sampler2D shadowtex0;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

	vec3 encodedNormal = texture(colortex2, texcoord).rgb;
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0);

	vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

	float depth = texture(depthtex0, texcoord).r;

	if ((depth < 1)&&(texture(colortex3, texcoord) == vec4(0))){
		if (depth != texture(depthtex1, texcoord).r){
			float mult = 1.0;
			mult *= encodedNormal.r;
			mult *= 1-encodedNormal.r;
			mult *= dot(encodedNormal.rgb, vec3(0,1,0));

			mult = clamp(mult*4+0.25, 0.55, 1.0);
			color.rgb *= mult;
		}
		color.rgb *= texture(colortex1, texcoord).rgb;
	}

	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	feetPlayerPos.xyz += cameraPosition;
	feetPlayerPos.xz *= 16;
	feetPlayerPos.xz = vec2(ivec2(feetPlayerPos.xz));
	feetPlayerPos.xz /= 16;
	feetPlayerPos.xyz -= cameraPosition;
	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
	vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
	vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;

	float shadow = step(shadowScreenPos.z - 0.0001, texture(shadowtex0, shadowScreenPos.xy).r);
	shadow = clamp(shadow, 0.75, 1.0);
	if (depth < 1){
		color.rgb *= shadow;
	}
}