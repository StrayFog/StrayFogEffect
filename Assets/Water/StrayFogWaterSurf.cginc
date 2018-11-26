#pragma target 4.6
#include "StrayFogCameraDepthTexture.cginc"
#include "StrayFogRiver.cginc"

//Tessellate Mesh
float _TessEdgeLength;
float _TessMaxDisp;
float _TessPhongStrength;

//Water
sampler2D _CameraDepthTexture;
sampler2D _GrabTex;
float4 _GrabTex_TexelSize;

//Light
float4 _Specular;
half _Smoothness;
half _Occlusion;

struct Input {
	half2 uv_WaterNormal;
	half2 uv_WaterFoam;
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

float2 RotationVector(float2 vec, float angle)
{
	float radZ = radians(-angle);
	float sinZ, cosZ;
	sincos(radZ, sinZ, cosZ);
	return float2(vec.x * cosZ - vec.y * sinZ,
		vec.x * sinZ + vec.y * cosZ);
}

//tessellate计算
float4 tessFunction(appdata_full v0, appdata_full v1, appdata_full v2)
{
	return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _TessEdgeLength, _TessMaxDisp);
}

float4 _GAmplitude;
float4 _GFrequency;
float4 _GSteepness;
float4 _GSpeed;
float4 _GDirectionAB;
float4 _GDirectionCD;

void tessVert(inout appdata_full v)
{	
	v.vertex.xyz += GerstnerWave(v.vertex,half3(1,1,1),
		_GSteepness, _GAmplitude, _GFrequency, _GSpeed, _GDirectionAB, _GDirectionCD);
}

void tessSurf(Input IN, inout SurfaceOutputStandardSpecular o) {
	//linearEyeDepth 像素深度
	float linearEyeDepth = StrayFogLinearEyeDepth(_CameraDepthTexture, IN.screenPos);

	float iTime = _Time.y;

	//float4 _FarBumpSampleParams = float4(0.25, 0.01, 0, 0);
	//float2 _FinalBumpSpeed01 = RotationVector(float2(0, 1), _WaterAngle + 10).xy * _WaterSpeed;
	//half2 uv_WaterNormal = IN.uv_WaterNormal;

	//uv_WaterNormal = StrayFogSampleNormal(_WaterNormal, uv_WaterNormal, _WaterNormalScale);

	//fixed4 farSample = tex2D(_WaterNormal, 
	//	uv_WaterNormal * _FarBumpSampleParams.x +
	//	_Time.x * _FinalBumpSpeed01 * _FarBumpSampleParams.x);
	//
	//fixed4 normalSample = tex2D(_WaterNormal, uv_WaterNormal + farSample.rg * 0.05);
	//normalSample = lerp(normalSample, farSample,saturate(linearEyeDepth * _FarBumpSampleParams.y));
	//
	//fixed3 lerp_WaterNormal = UnpackScaleNormal(normalSample,_WaterNormalScale);
	//float4 grabUV = IN.screenPos;
	////grabUV.xy += lerp_WaterNormal.xy * _WaterRefraction;
	//float4 waterGrabColor = tex2Dproj(_GrabTex, grabUV);

	//half range = saturate(_WaterDepth * linearEyeDepth);
	//range = 1.0 - range;
	//range = lerp(range, pow(range,3), 0.5);

	//// Calculate the color tint
	//half4 waterColor= lerp(_WaterDeepColor, _WaterShallowColor, range);

	//o.Normal = GerstNormal(uv_WaterNormal);
	//o.Emission = UnpackNormal(tex2D(_WaterNormal, GerstNormal(uv_WaterNormal)));
	o.Specular = _Specular;
	o.Smoothness = _Smoothness;
	o.Occlusion = _Occlusion;
	o.Alpha = linearEyeDepth;
}