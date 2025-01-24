#version 330 compatibility
#include "/lib/settings.glsl"

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 glcolor;

flat in int isGrass;
flat in int isLeaves;

layout(location = 0) out vec4 color;

void main() {
	color = texture(gtexture, texcoord) * glcolor;

	#ifdef FAST_LEAVES
	if (isLeaves == 0){
		if(color.a < 0.1){
		discard;
		}
	}
	#else
		if(color.a < 0.1){
		discard;
		}
	#endif

	#ifdef INVISIBLE_GRASS
		if (bool(isGrass)){
			discard;
		}
	#endif
}