#ifndef STRAYFOGRIVERWAVE_CG_INCLUDED
#define STRAYFOGRIVERWAVE_CG_INCLUDED
#pragma target 4.6

sampler2D _WaterNormal;
float4 _WaterNormal_ST;

//Tessellate Wave 
half _WaterSpeed;
half _WaterAngle;
half _WaterTessScale;

//Tessellate Mesh
float _TessEdgeLength;
float _TessMaxDisp;
float _TessPhongStrength;
sampler2D _TesselationTex;


sampler2D _CameraDepthTexture;

sampler2D _GrabTex;
float4 _GrabTex_TexelSize;

half _Specular;
fixed _Gloss;

struct Input {
	INTERNAL_DATA
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

void tessVert(inout appdata_full v)
{
	int _UVVDirection1UDirection0 = 0;
	float4 _WaterMixSpeed = float4 (0.01, 0.05, 0, 0);
	float4 _WaterMainSpeed = float4(1, 1, 0, 0);

	float mulTime445 = _Time.y * 1;
	float2 Direction723 = RotationVector(float2(0,1),_WaterAngle).xy * _WaterSpeed;

	float2 uv_WaterNormal = v.texcoord.xy * _WaterNormal_ST.xy + _WaterNormal_ST.zw;
	float2 panner612 = (uv_WaterNormal + mulTime445 * Direction723);
	float2 WaterSpeedValueMix516 = panner612;
	float2 uv4_TexCoord829 = v.texcoord3.xy * float2(1, 1) + float2(0, 0);
	float2 appendResult823 = half2(Direction723.x * uv4_TexCoord829.x, Direction723.y * uv4_TexCoord829.y);
	float mulTime815 = _Time.y * 0.3;
	float temp_output_816_0 = (mulTime815 * 0.15);
	float temp_output_818_0 = frac((temp_output_816_0 + 1));
	float2 temp_output_826_0 = (appendResult823 * temp_output_818_0);
	float2 WaterSpeedValueMainFlowUV1830 = (uv_WaterNormal + temp_output_826_0);
	float2 temp_output_825_0 = (appendResult823 * frac((temp_output_816_0 + 0.5)));
	float2 WaterSpeedValueMainFlowUV2831 = (uv_WaterNormal + temp_output_825_0);
	float clampResult845 = clamp(abs(((temp_output_818_0 + -0.5) * 2)), 0, 1);
	float SlowFlowHeightBase835 = clampResult845;
	float lerpResult840 = lerp(tex2Dlod(_TesselationTex, half4(WaterSpeedValueMainFlowUV1830, 0, 1)).g, tex2Dlod(_TesselationTex, half4(WaterSpeedValueMainFlowUV2831, 0, 1)).r, SlowFlowHeightBase835);
	float3 ase_vertexNormal = v.normal.xyz;
	v.vertex.xyz += (((_WaterTessScale * tex2Dlod(_TesselationTex, half4(WaterSpeedValueMix516, 0, 1)).r) + (_WaterTessScale * lerpResult840)) * ase_vertexNormal);	
}

void surf(Input IN, inout SurfaceOutputStandardSpecular o) {
	float linearEyeDepth = 1;
	//linearEyeDepth 像素深度
	{
		linearEyeDepth = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, IN.screenPos))) - IN.screenPos.w;
	}	
	o.Albedo = 0;
	o.Alpha = linearEyeDepth;
}
#endif