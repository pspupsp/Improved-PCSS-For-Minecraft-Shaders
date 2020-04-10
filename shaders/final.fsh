/*
Copyright 2020 pspupsp

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#version 120

uniform sampler2D gcolor;
uniform sampler2D noisetex;
uniform sampler2D depthtex1;
uniform sampler2D shadowtex1;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform float frameTimeCounter;

varying vec2 texcoord;



//----------Settings----------//
#define PCSS_GLSL_2

#define USE_DISTORT_FACTOR 1

#define PCSS_DEPTH_SEARCH_SAMPLES 4
#define PCSS_FLITER_SEARCH_SAMPLES 8

#define SHADOW_MAP_BIAS 0.90

const float sunPathRotation        = -40.0;
const float ambientOcclusionLevel  = 0.5;

const int   shadowMapResolution    = 2048;
const float shadowDistance         = 120.0;
const int   noiseTextureResolution = 64;
//----------End----------//

#include "PCSS.glsl"



//---------------------------------------------------------------------------------
vec4 GetViewSpacePosition(in vec2 texcoord, in float senceDepth)
{
	vec4 fragPosition = vec4(texcoord * 2.0 - 1.0, senceDepth * 2.0 - 1.0, 1.0);
		 fragPosition = gbufferProjectionInverse * fragPosition;
		 fragPosition /= fragPosition.w;

	return fragPosition;
}
//---------------------------------------------------------------------------------
float DistortFactor(in vec2 positon, out float distort)
{
	distort = length(positon);
	return 1.0 + SHADOW_MAP_BIAS * (distort - 1.0);
}

vec4 ProjectWorldSpaceToShadowSpace(
									in vec4 worldSpacePosition,
									out float distort,
									out float distortFactor
								   )
{
	//Transform from world space to shadow space
	vec4 shadowSpacePosition = shadowProjection * shadowModelView * worldSpacePosition;
		 shadowSpacePosition /= shadowSpacePosition.w;

	distortFactor = DistortFactor(shadowSpacePosition.xy, distort);
	shadowSpacePosition.xy /= distortFactor;

	shadowSpacePosition = shadowSpacePosition * 0.5 + 0.5;
	return shadowSpacePosition;
}
//---------------------------------------------------------------------------------
float ShadowsGenerator(
					   in vec4 worldSpacePosition,
					   in vec2 texcoord,
					   in float senceDepth
					  )
{
	if(senceDepth > 0.999999)
	{
		return 1.0;
	}

	vec2 dither = texture2D(noisetex, texcoord * float(noiseTextureResolution) + sin(frameTimeCounter)).xy;

	float distort, distortFactor;
	vec4 shadowSpacePosition = ProjectWorldSpaceToShadowSpace(
															  worldSpacePosition,
															  distort,
															  distortFactor
															 );
	shadowSpacePosition.z -= 0.0008;



	float shadows = GetPCSS(
							shadowtex1,
							shadowSpacePosition,
							shadowDistance,
							distortFactor,
							dither
						   );

	return shadows;
}
//---------------------------------------------------------------------------------
void main()
{
	vec3 color = texture2D(gcolor, texcoord).rgb;



	float senceDepth = texture2D(depthtex1, texcoord).x;
	vec4 viewSpacePosition = GetViewSpacePosition(texcoord, senceDepth);
	vec4 worldSpacePosition = gbufferModelViewInverse * viewSpacePosition;

	float shadows = ShadowsGenerator(worldSpacePosition, texcoord, senceDepth);
	color *= shadows * 0.7 + 0.3;



	color = clamp(color, 0.0, 1.0);
	gl_FragColor = vec4(color, 1.0);
}
