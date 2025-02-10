#version 330 compatibility
#include "/lib/common.glsl"
#include "/lib/settings.glsl"

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

	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	feetPlayerPos.y += clamp(length(viewPos)*0.005, 0.1, 0.5);
	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	shadowClipPos.z -= 0.0001;
	shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
	vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
	vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;

	float shadow = 0;
	int count = 0;
	for (float x = -8; x <= 8; x+=1.5){
		for (float y = -8; y <= 8; y+=1.5){
			float noise = IGN(texcoord, frameCounter, vec2(viewWidth, viewHeight));

			float theta = noise * radians(360.0);
			float cosTheta = cos(theta);
			float sinTheta = sin(theta);

			mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta);
			shadow += step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy+((vec2(x,y)*rotation)/vec2(shadowMapResolution))).r)+((abs(x)+abs(y))/50);
			count++;
		}
	}
	shadow /= count;
	shadow *= dot(worldLightVector, normal)*4;
	shadow = clamp(shadow, 0.65, 1.0);

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
		color.rgb *= shadow;
	}
}