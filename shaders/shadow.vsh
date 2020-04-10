#version 120

#define SHADOW_MAP_BIAS 0.90

varying vec4 color;
varying vec2 texcoord;

float DistortFactor(in vec2 positon, out float distort)
{
	distort = length(positon);
	return 1.0 + SHADOW_MAP_BIAS * (distort - 1.0);
}

void main()
{
	gl_Position = ftransform();

	float distort;
	gl_Position.xy /= DistortFactor(gl_Position.xy, distort);

	color = gl_Color;
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
}
