#ifndef STRAYFOGRIVERWAVE_CG_INCLUDED
#define STRAYFOGRIVERWAVE_CG_INCLUDED
#pragma target 4.6

sampler2D _WaterNormal;
sampler2D _WaterFoam;
float4 _WaterNormal_TexelSize;

//Tessellate Wave 
half _WaterSpeed;
half _WaterAngle;
half _WaterTessScale;
half _WaterNormalScale;
half _WaterWaveOverlay;
half _WaterRefraction;
float4 _WaterShallowColor;
float4 _WaterDeepColor;
half _WaterDepth;

//Tessellate Mesh
float _TessEdgeLength;
float _TessMaxDisp;
float _TessPhongStrength;
sampler2D _TesselationTex;
float4 _TesselationTex_ST;

sampler2D _CameraDepthTexture;

sampler2D _GrabTex;
float4 _GrabTex_TexelSize;

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

fixed3 TexcoordNormal(sampler2D _tex,float2 _texcoord,bool _isTex2Dlod)
{
	float iTime = _Time.y;

	float2 pd = RotationVector(float2(0, 1), _WaterAngle + _WaterWaveOverlay).xy * _WaterSpeed * iTime;
	float2 nd = RotationVector(float2(0, 1), _WaterAngle - _WaterWaveOverlay).xy * _WaterSpeed * iTime;

	fixed3 bumpPd = UnpackScaleNormal(
		_isTex2Dlod ? (tex2Dlod(_tex, float4(_texcoord + pd, 0, 0))):(tex2D(_tex, float4(_texcoord + pd, 0, 0)))
		, _WaterNormalScale).rgb;
	fixed3 bumpNd = UnpackScaleNormal(
		_isTex2Dlod ? (tex2Dlod(_tex, float4(_texcoord + nd, 0, 0))) : (tex2D(_tex, float4(_texcoord + nd, 0, 0)))
		,_WaterNormalScale).rgb;
	return normalize(bumpPd + bumpNd);
}


void tessVert(inout appdata_full v)
{
	float2 uv_WaterNormal = v.texcoord.xy * _TesselationTex_ST.xy + _TesselationTex_ST.zw;
	v.vertex.xyz += v.normal * TexcoordNormal(_TesselationTex, uv_WaterNormal, true) * _WaterTessScale;
	
	/*float mulTime445 = _Time.y * 1;
	float2 Direction723 = RotationVector(float2(0, 1), _WaterAngle).xy * _WaterSpeed;	
	float2 uv_WaterNormal = v.texcoord.xy * _TesselationTex_ST.xy + _TesselationTex_ST.zw;
	float2 panner612 = (uv_WaterNormal + mulTime445 * Direction723);
	float2 WaterSpeedValueMix516 = panner612;
	float2 uv4_TexCoord829 = v.texcoord.xy * float2(1, 1) + float2(0, 0);
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
	v.vertex.xyz += (((_WaterTessScale * tex2Dlod(_TesselationTex, half4(WaterSpeedValueMix516, 0, 1)).r) + (_WaterTessScale * lerpResult840)) * ase_vertexNormal);*/
}

void tessSurf(Input IN, inout SurfaceOutputStandardSpecular o) {
	float linearEyeDepth = 1;
	//linearEyeDepth 像素深度
	{
		linearEyeDepth = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, IN.screenPos))) - IN.screenPos.w;
	}	

	float iTime = _Time.y;
	fixed3 lerp_WaterNormal = TexcoordNormal(_WaterNormal, IN.uv_WaterNormal, false);

	float4 grabUV = IN.screenPos;
	grabUV.xy += lerp_WaterNormal.xy * _WaterRefraction;
	float4 waterGrabColor = tex2Dproj(_GrabTex, grabUV);

	half range = saturate(_WaterDepth * linearEyeDepth);
	range = 1.0 - range;
	range = lerp(range, pow(range,3), 0.5);

	// Calculate the color tint
	half4 waterColor= lerp(_WaterDeepColor, _WaterShallowColor, range);

	o.Normal = lerp_WaterNormal;
	o.Emission = waterGrabColor.rgb;
	o.Specular = _Specular;
	o.Smoothness = _Smoothness;
	o.Occlusion = _Occlusion;
	o.Alpha = linearEyeDepth;

	

	
	//o.Albedo = waterGrabColor.rgb * waterColor.rgb;
}
#endif