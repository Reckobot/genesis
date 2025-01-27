#version 330 compatibility
#include "/lib/distort.glsl"

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 glcolor;
flat in int isGrass;

layout(location = 0) out vec4 color;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	if(color.a < 0.1){
		discard;
	}

	if (bool(isGrass)){
		discard;
	}
}