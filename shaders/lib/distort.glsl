vec3 distortShadowClipPos(vec3 shadowClipPos){
    float distortionFactor = length(shadowClipPos.xy); // distance from the player in shadow clip space
    distortionFactor += 0.25; // very small distances can cause issues so we add this to slightly reduce the distortion

    shadowClipPos.xy /= distortionFactor;
    shadowClipPos.z *= 0.25; // increases shadow distance on the Z axis, which helps when the sun is very low in the sky
    return shadowClipPos;
}