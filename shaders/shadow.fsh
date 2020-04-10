#version 120

uniform sampler2D tex;

varying vec4 color;
varying vec2 texcoord;

void main()
{
	gl_FragData[0] = color * texture2D(tex, texcoord);
}
