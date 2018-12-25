#ifndef STRAYFOGWATER_INCLUDED
#define STRAYFOGWATER_INCLUDED

sampler2D _CameraDepthTexture;
struct appdata_water {
	float4 vertex : POSITION;
	float4 tangent : TANGENT;
	float3 normal : NORMAL;
	//float4 texcoord : TEXCOORD0;
	fixed4 color : COLOR;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

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


//Wave
float4 _GerstnerVertexIntensity;

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
	o.Alpha = 1;
}
#endif