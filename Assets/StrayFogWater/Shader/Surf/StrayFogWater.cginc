#ifndef STRAYFOGWATER_INCLUDED
#define STRAYFOGWATER_INCLUDED
#include "StrayFogWater_Helper.cginc"

//Water
sampler2D _NormalTex2D;
float4 _NormalTex2D_TexelSize;
float _NormalScale;
float _WaterAngle;
float _WaterOverlap;
float _WaterSpeed;
float _WaterRefraction;
float4 _ShalowColor;
float4 _DeepColor;

//Water Wave
float _NormalSmoothing;
float _Amplitude;
float _Frequency;
float _Speed;
float _Steepness;
float4 _Speeds;
float4 _SpeedsLarge;
float4 _WSpeed;
float4 _WDirectionAB;
float4 _WDirectionCD;

//Water Foam
sampler2D _FoamTex2D;

//Water Noise
sampler2D _NoiseTex2D;

//Tessellate Mesh
float _TessEdgeLength;
float _TessMaxDisp;
float _TessPhongStrength;
float _TessDisplacement;
sampler2D _TesselationTex;

//Light
float4 _Specular;
half _Smoothness;
half _Occlusion;

sampler2D _CameraDepthTexture;

struct Input {
	float2 uv_TesselationTex;
	float2 uv_NormalTex2D;
	float2 uv_FoamTex2D;
	float2 uv_NoiseTex2D;
	float3 worldNormal;
	float3 viewDir;
	float3 worldPos;
	INTERNAL_DATA
	float4 vertexColor : COLOR;
	float4 screenPos;
};

// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
// #pragma instancing_options assumeuniformscaling
UNITY_INSTANCING_BUFFER_START(Props)
// put more per-instance properties here
UNITY_INSTANCING_BUFFER_END(Props)

//水纹波动
void WaterWaveGerstner(half3 vtx,out half3 offsets, out half3 nrml)
{
	half4 worldSpaceVertex = mul(unity_ObjectToWorld, (vtx));
	offsets = 0;
	nrml = half3(0,0,1);
#if _WAVEMODE_WAVE
	Wave(
		offsets, nrml, vtx, worldSpaceVertex,
		_Amplitude,
		_Frequency,
		_Speed, 
		_NormalSmoothing
	);
#endif

#if _WAVEMODE_GERSTNER

	half3 vtxForAni = (worldSpaceVertex.xyz).xzz; // REMOVE VARIABLE
	Gerstner(
		offsets, nrml, vtx, vtxForAni,				// offsets, nrml will be written
		_Amplitude,									// amplitude
		_Frequency,											// frequency
		_Steepness,											// steepness
		_WSpeed,											// speed
		_WDirectionAB,										// direction # 1, 2
		_WDirectionCD,										// direction # 3, 4									
		_NormalSmoothing
	);
#endif
}

//tessellate计算
float4 StrayFogTessFunction(appdata_full v0, appdata_full v1, appdata_full v2)
{
	return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _TessEdgeLength, _TessMaxDisp);
}

void StrayFogVert(inout appdata_full v)
{
	float3 d = tex2Dlod(_TesselationTex, float4(v.texcoord.xy, 0, 0)).rgb * _TessDisplacement;
	half3 offsets = v.normal * d;
	half3 nrml = v.normal * d;
	//WaterWaveGerstner(v.vertex,offsets, nrml);
	v.vertex.xyz += offsets;
	v.normal += nrml;
	v.color.a = offsets.y;
}

//SurfaceOutputStandardSpecular
void tessSurf(Input IN, inout SurfaceOutputStandardSpecular o) {
	//linearEyeDepth 像素深度
	float linearEyeDepth = StrayFogLinearEyeDepth(_CameraDepthTexture, IN.screenPos);

	float d = tex2D(_TesselationTex, IN.uv_TesselationTex).r * _TessDisplacement;

	half2 uv_NormalTex2D = IN.uv_NormalTex2D;
	half2 flowSpeed = StrayFogRotateAround(float2(0, 1), _WaterAngle) * _WaterSpeed * _Time.x;
	
	half4 CnormalTex0 = tex2D(_NormalTex2D, uv_NormalTex2D + flowSpeed);
	half4 CnormalTex1 = tex2D(_NormalTex2D, uv_NormalTex2D * 0.75 - (flowSpeed*0.25));
	half3 cNormal = BlendNormals(UnpackScaleNormal(CnormalTex0, _NormalScale), UnpackScaleNormal(CnormalTex1, _NormalScale));
	o.Normal = cNormal;

//	half4 waterFoam = tex2D(_FoamTex2D, IN.uv_FoamTex2D);
//	half4 waterNoise = tex2D(_NoiseTex2D, IN.uv_NoiseTex2D +
//		StrayFogRotateAround(float2(0, 1), _Time.x * _WaterAngle));
//
//	half2 uv_NormalTex2D = IN.uv_NormalTex2D;
//	//Normal
//	{
//		float overlapAngle = _WaterOverlap * sin(_Time.x + _WaterOverlap) * cos(_Time.x - _WaterOverlap) * 0.05;
//
//		float2 flowDir1 = StrayFogRotateAround(float2(0, 1), _WaterAngle + overlapAngle) * _WaterSpeed * _Time.x;
//		float4 farSample1 = tex2D(_NormalTex2D, uv_NormalTex2D + flowDir1);
//		float4 normalSample1 = tex2D(_NormalTex2D, uv_NormalTex2D +
//			flowDir1 * _Time.y * _NormalTex2D_TexelSize.xy * _WaterSpeed +
//			farSample1.xz * 0.05 * waterNoise.x);
//		float3 normal1 = UnpackScaleNormal(normalSample1 * farSample1, _NormalScale);
//
//		float2 flowDir2 = StrayFogRotateAround(float2(0, 1), _WaterAngle - overlapAngle) * _WaterSpeed * _Time.x;
//		float4 farSample2 = tex2D(_NormalTex2D, uv_NormalTex2D + flowDir2);
//		float4 normalSample2 = tex2D(_NormalTex2D, uv_NormalTex2D +
//			flowDir2 * _Time.y * _NormalTex2D_TexelSize.xy * _WaterSpeed +
//			farSample2.yw * 0.05 * waterNoise.x);
//		float3 normal2 = UnpackScaleNormal(normalSample2* farSample2, _NormalScale);
//
//		o.Normal = BlendNormals(normal1, normal2);
//	}
//
	float3 worldNormal = WorldNormalVector(IN, o.Normal);
	float3 worldView = UnityObjectToWorldDir(IN.viewDir);
#ifdef CULL_FRONT
	worldView = -worldView;
#endif
	float3  worldLightDir = UnityWorldSpaceLightDir(IN.worldPos);
	float3 worldReflect = reflect(-worldView, worldNormal);

	o.Albedo = 0.5;
	o.Emission = 0;
	o.Specular = _Specular;
	o.Smoothness = _Smoothness;
	o.Occlusion = _Occlusion;
}
#endif