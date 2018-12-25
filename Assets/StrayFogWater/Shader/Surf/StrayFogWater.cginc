#ifndef STRAYFOGWATER_INCLUDED
#define STRAYFOGWATER_INCLUDED
#include "StrayFogWater_GerstnerWave.cginc"
#include "StrayFogWater_Helper.cginc"
sampler2D _CameraDepthTexture;


struct Input {
	float4 BumpUVs;
	float4 grabUV;
	float4 ViewRay_WaterYpos;

#if defined(USINGWATERPROJECTORS)
	float4 projectorScreenPos;
#else
	float4 BumpSmallAndFoamUVs;
#endif

	fixed4 color : COLOR0;

	float facingSign : VFACE;
	float3 viewDir;
	float3 worldNormal;
	float3 worldPos;
	INTERNAL_DATA
};

// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
// #pragma instancing_options assumeuniformscaling
UNITY_INSTANCING_BUFFER_START(Props)
// put more per-instance properties here
UNITY_INSTANCING_BUFFER_END(Props)

void StrayFogVert(inout appdata_full v,out Input o)
{
	UNITY_INITIALIZE_OUTPUT(Input, o);
#ifdef _WAVEFEATURE_GERSTNER
#endif
}

//SurfaceOutputStandardSpecular
void StrayFogSurf(Input IN, inout SurfaceOutputStandardSpecular o) {
#ifdef _WAVEFEATURE_GERSTNER
	o.Emission = 0.5;
#endif
}
#endif