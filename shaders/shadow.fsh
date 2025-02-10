#version 330 compatibility
#include "/lib/settings.glsl"

uniform sampler2D colortex0;

in vec2 texcoord;
flat in int isGrass;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

	if (color.a < 0.1){
		discard;
	}

	#ifdef INVISIBLE_GRASS
		if (bool(isGrass)){
			discard;
		}
	#endif
}