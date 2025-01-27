#define SHADOW_RES 4096 //[128 256 512 1024 2048 4096 8192]
#define SHADOW_DIST 100 //[50 100 200 300 400 500 600 700 800 900 1000]

const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;

const int shadowMapResolution = SHADOW_RES;
const float shadowDistance = SHADOW_DIST;

vec3 distortShadowClipPos(vec3 shadowClipPos){
    float distortionFactor = length(shadowClipPos.xy); // distance from the player in shadow clip space
    distortionFactor += 0.25; // very small distances can cause issues so we add this to slightly reduce the distortion

    shadowClipPos.xy /= distortionFactor;
    shadowClipPos.z *= 0.25; // increases shadow distance on the Z axis, which helps when the sun is very low in the sky
    return shadowClipPos;
}