const float ambientOcclusionLevel = 0;

uniform sampler2D colortex5;

uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform float far;
uniform int isEyeInWater;
uniform float playerMood;
uniform float constantMood;
uniform int frameCounter;

uniform vec3 cameraPosition;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform int logicalHeightLimit;

uniform float viewWidth;
uniform float viewHeight;

const vec3 alphaFogColor = vec3(0.75, 0.85, 1.0);

vec3 BSC(vec3 color, float brt, float sat, float con)
{
	// Increase or decrease theese values to adjust r, g and b color channels seperately
	const float AvgLumR = 0.5;
	const float AvgLumG = 0.5;
	const float AvgLumB = 0.5;
	
	const vec3 LumCoeff = vec3(0.2125, 0.7154, 0.0721);
	
	vec3 AvgLumin  = vec3(AvgLumR, AvgLumG, AvgLumB);
	vec3 brtColor  = color * brt;
	vec3 intensity = vec3(dot(brtColor, LumCoeff));
	vec3 satColor  = mix(intensity, brtColor, sat);
	vec3 conColor  = mix(AvgLumin, satColor, con);
	
	return conColor;
}

float increment(float original, float numerator, float denominator){
    return round(original * denominator / numerator) * numerator / denominator;
}

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
	vec4 homPos = projectionMatrix * vec4(position, 1.0);
	return homPos.xyz / homPos.w;
}

float getFresnel(float f0, vec3 dir, vec3 norm){
	float fresnel = pow(f0 + (1 - f0) * (1-dot(dir, norm)), 5);
    return fresnel;
}

float getRoughness(vec2 coord){
	float roughness = pow(1 - texture(colortex5, coord).r, 2);

	roughness = (2/roughness)-2;

    return roughness;
}

float getLuminance(vec3 c){
	return dot(vec3(0.2126, 0.7152, 0.0722), c);
}

float fogify(float x, float w) {
	return w / (x * x + w);
}

float IGN(vec2 coord, int frame, vec2 res)
{
    float x = float(coord.x * res.x) + 5.588238 * float(frame);
    float y = float(coord.y * res.y) + 5.588238 * float(frame);
    return mod(52.9829189 * mod(0.06711056*float(x) + 0.00583715*float(y), 1.0), 1.0);
}

vec3 calcSkyColor(vec3 pos) {
	float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	return mix(BSC(skyColor, 1.1, 1.0, 1.0), fogColor, fogify(max(upDot, 0.0), 0.01));
}

vec3 screenToView(vec3 screenPos) {
	vec4 ndcPos = vec4(screenPos, 1.0) * 2.0 - 1.0;
	vec4 tmp = gbufferProjectionInverse * ndcPos;
	return tmp.xyz / tmp.w;
}


const int RGBA16F = 0;
const int colortex0Format = RGBA16F;