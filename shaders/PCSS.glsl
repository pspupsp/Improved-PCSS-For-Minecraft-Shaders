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

#if !defined(PCSS_GLSL_2) && !defined(PCSS_GLSL_3) && !defined(PCSS_GLSL_4)
#error you must define the supported shading language: PCSS_GLSL_2, PCSS_GLSL_3 or PCSS_GLSL_4
#endif

#if !defined(PCSS_DEPTH_SEARCH_SAMPLES) || (PCSS_DEPTH_SEARCH_SAMPLES <= 0)
#error you must define "PCSS_DEPTH_SEARCH_SAMPLES" larger than '0'!
#endif

#if !defined(PCSS_FLITER_SEARCH_SAMPLES) || (PCSS_FLITER_SEARCH_SAMPLES <= 0)
#error you must define "PCSS_FLITER_SEARCH_SAMPLES" larger than '0'!
#endif

#if !defined(USE_DISTORT_FACTOR) || (USE_DISTORT_FACTOR != 0 && USE_DISTORT_FACTOR != 1)
#error you must define "USE_DISTORT_FACTOR" as '0' or '1'!
#endif

#define PCSS_Texture2D(tex) sampler2D tex

#if defined(PCSS_GLSL_3) || defined(PCSS_GLSL_4)
	#define PCSS_Texture(tex, coord) texture(tex, coord)
	#define PCSS_TextureLod(tex, coord, lod) textureLod(tex, coord, lod)
#elif defined(PCSS_GLSL_2)
	#define PCSS_Texture(tex, coord) texture2D(tex, coord)
	#define PCSS_TextureLod(tex, coord, lod) texture2DLod(tex, coord, lod)
#endif









float GetPCSS(
			 in PCSS_Texture2D(shadowTex),
			 in vec4 shadowPos,
			 in float shadowMapDistance,
		#if USE_DISTORT_FACTOR == 1
			 in float distortFactor,
		#endif
			 in vec2 dither
			)
{
	int searchSamp = PCSS_DEPTH_SEARCH_SAMPLES;
	int shadowSamp = PCSS_FLITER_SEARCH_SAMPLES;

	float PI = 3.14159265358;
	float sampRange = 120.0 / shadowMapDistance;




	float searchStepCycle = 2.0 / float(searchSamp);
	float searchStepSize = sampRange / float(searchSamp);

	float avgDepth = 0.0;
	for(int sampD = 0; sampD < searchSamp; sampD++)
	{
		float count = float(sampD) * dither.x;
		float alpha = count * PI * searchStepCycle * 3.25;

		vec2 offs = vec2(sin(alpha), cos(alpha)) * 0.002;
	#if USE_DISTORT_FACTOR == 1
		vec2 sampPos = shadowPos.xy * distortFactor + offs * searchStepSize * sqrt(count);
			 sampPos /= distortFactor;
	#elif USE_DISTORT_FACTOR == 0
		vec2 sampPos = shadowPos.xy + offs * searchStepSize * sqrt(count);
	#endif

		float depthSamp = PCSS_TextureLod(shadowTex, sampPos.xy, 2.0).x;
			  depthSamp = max(shadowPos.z - depthSamp, 0.0);
		avgDepth += depthSamp * depthSamp;
	}
	avgDepth /= float(searchSamp);
	avgDepth = sqrt(avgDepth);




#if USE_DISTORT_FACTOR == 1
	float spread = (distortFactor / (float(shadowMapResolution) * sampRange)) * 8.0;
#elif USE_DISTORT_FACTOR == 0
	float spread = 8.0 / (float(shadowMapResolution) * sampRange);
#endif
	spread = max(avgDepth * 0.1375, spread);



	float shadowStepCycle = 2.0 / float(shadowSamp);
	float shadowStepSize = sampRange / float(shadowSamp);

	float shadows = 0.0;
	for(int sampS = 0; sampS < shadowSamp; sampS++)
	{
		float count = float(sampS) * dither.y;
		float alpha = count * PI * shadowStepCycle * 3.25;

		vec2 offs = vec2(sin(alpha), cos(alpha));
	#if USE_DISTORT_FACTOR == 1
		vec2 sampPos = shadowPos.xy * distortFactor + offs * spread * shadowStepSize * sqrt(count);
			 sampPos /= distortFactor;
	#elif USE_DISTORT_FACTOR == 0
		vec2 sampPos = shadowPos.xy + offs * spread * shadowStepSize * sqrt(count);
	#endif

		float shadowSamp = PCSS_TextureLod(shadowTex, sampPos.xy, 0.0).x;
			  shadowSamp = step(shadowPos.z, shadowSamp);
		shadows += shadowSamp;
	}
	shadows /= float(shadowSamp);

	return shadows;
}
