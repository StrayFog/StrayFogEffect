#ifndef STRAYFOGWATER_INCLUDED
#define STRAYFOGWATER_INCLUDED
//Water
sampler2D _WaterNormal;
float _WaterNormalScale;

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

struct Input {
	float2 uv_TesselationTex;
	float2 uv_WaterNormal;
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

//tessellate计算
float4 tessFunction(appdata_full v0, appdata_full v1, appdata_full v2)
{
	return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _TessEdgeLength, _TessMaxDisp);
}

void tessVert(inout appdata_full v)
{
	/*v.vertex.xyz += GerstnerWave(v.vertex,half3(1,1,1),
		_GSteepness, _GAmplitude, _GFrequency, _GSpeed, _GDirectionAB, _GDirectionCD);*/
	//float d = tex2Dlod(_TesselationTex, float4(v.texcoord.xy, 0, 0)).r * _TessDisplacement;
	//v.vertex.xyz += v.normal*d;
	float3 d = tex2Dlod(_TesselationTex, float4(v.texcoord.xy, 0, 0)).rgb * _TessDisplacement;
	v.vertex.xyz += v.normal * d;
}

//SurfaceOutputStandardSpecular
void tessSurf(Input IN, inout SurfaceOutputStandardSpecular o) {
	//linearEyeDepth 像素深度
	//float linearEyeDepth = StrayFogLinearEyeDepth(_CameraDepthTexture, IN.screenPos);

	float d = tex2D(_TesselationTex, IN.uv_TesselationTex).r * _TessDisplacement;
	float3 worldNormal = WorldNormalVector(IN, o.Normal);

	float3 normal = UnpackScaleNormal(tex2D(_WaterNormal, IN.uv_WaterNormal), _WaterNormalScale);

	o.Normal = normal;

	o.Specular = _Specular;
	o.Smoothness = _Smoothness;
	o.Occlusion = _Occlusion;
}
#endif