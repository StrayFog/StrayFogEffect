#ifndef STRAYFOGRIVERWAVE_CG_INCLUDED
#define STRAYFOGRIVERWAVE_CG_INCLUDED

#define MOD2 float2(4.438975,3.972973);

float _EdgeLength;
float _TessMaxDisp;
float _TessPhongStrength;
sampler2D _WaterTesselation;
float4 _WaterTesselation_ST;
float _TessDisplacement;

#pragma target 4.6

sampler2D _CameraDepthTexture;

sampler2D _GrabTex;
float4 _GrabTex_TexelSize;
sampler2D _WaterNormal;
float _WaterNormalScale;
float _WaterAngle;
float _WaterSpeed;

sampler2D _WaterFoam;

float _WaterDepth;
float4 _ShallowColor;
float4 _DeepColor;
float _RefractDistortion;

struct Input {
	half2 uv_WaterNormal;
	half2 uv_WaterFoam;
	float3 worldNormal;
	float3 worldPos;
	float3 viewDir;
	INTERNAL_DATA
		float4 vertexColor : COLOR0;
	float4 screenPos;
};

half _Glossiness;
half _Metallic;

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

float Hash(float p)
{
	// https://www.shadertoy.com/view/4djSRW - Dave Hoskins
	float2 mod2 = MOD2;
	float2 p2 = frac(float2(p, p) * mod2);
	p2 += dot(p2.yx, p2.xy + 19.19);
	return frac(p2.x * p2.y);
	//return fract(sin(n)*43758.5453);
}

float SmoothNoise(in float2 o)
{
	float2 p = floor(o);
	float2 f = frac(o);

	float n = p.x + p.y*57.0;

	float a = Hash(n + 0.0);
	float b = Hash(n + 1.0);
	float c = Hash(n + 57.0);
	float d = Hash(n + 58.0);

	float2 f2 = f * f;
	float2 f3 = f2 * f;

	float2 t = 3.0 * f2 - 2.0 * f3;

	float u = t.x;
	float v = t.y;

	float res = a + (b - a)*u + (c - a)*v + (a - b + d - c)*u*v;

	return res;
}

float3 Tonemap(float3 x)
{
	float a = 0.010;
	float b = 0.132;
	float c = 0.010;
	float d = 0.163;
	float e = 0.101;

	return (x * (a * x + b)) / (x * (c * x + d) + e);
}

float4 WaveOffset(float2 uv)
{
	float4 result = float4(uv,0,0);
	result.xy += RotationVector(float2(0, 1) * _Time.y * _WaterSpeed, _WaterAngle);
	return result;
}

float3 SmoothWave(float3 _wave)
{
	float3 vResult = float3(0, 0, 0);
	float fTot = 0.0;
	float2 fragCoord = _wave.xy;
	for (int i = 0; i < 10; i++)
	{
		float3 vRandom = float3(SmoothNoise(fragCoord.xy + fTot),
			SmoothNoise(fragCoord.yx + fTot + 42.0),
			SmoothNoise(fragCoord.xx + fragCoord.yy + fTot + 42.0)) * 2.0 - 1.0;
		vResult += normalize(vRandom);
		fTot += 1.0;
	}
	vResult /= fTot;
	return vResult;
}

//tessellate计算
float4 tessFunction(appdata_full v0, appdata_full v1, appdata_full v2)
{
	return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _EdgeLength, _TessMaxDisp);
}

void tessVert(inout appdata_full v)
{
	float3 wave = tex2Dlod(_WaterTesselation, float4(WaveOffset(v.texcoord.xy).xy, 0, 0)).rbg * _TessDisplacement;
	v.vertex.xyz += v.normal * SmoothWave(wave);
}

void surf(Input IN, inout SurfaceOutputStandard o) {
	float linearEyeDepth = 1;
	//linearEyeDepth 像素深度
	{
		linearEyeDepth = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, IN.screenPos))) - IN.screenPos.w;
	}

	//计算法线，光反射强度
	float3 eyeVec = normalize(IN.worldPos.xyz - _WorldSpaceCameraPos);
	float3 normal = UnpackScaleNormal(tex2D(_WaterNormal, WaveOffset(IN.uv_WaterNormal)), _WaterNormalScale);		

	float3 worldNormal = WorldNormalVector(IN, normal);
	float3 lightDir = UnityWorldSpaceLightDir(IN.worldPos);
	
	float NdotV = max(0, dot(worldNormal, eyeVec));// 漫反射强度
	NdotV *= dot(reflect(lightDir, worldNormal), eyeVec);//光反射强度

	//水底纹理
	float4 grabUV = IN.screenPos;
	grabUV.xy += normal.xy * _RefractDistortion * _GrabTex_TexelSize;
	float4 grabColor = tex2Dproj(_GrabTex, grabUV);

	float4 foamColor = tex2D(_WaterFoam, IN.uv_WaterFoam);

	//水深
	half depth = saturate(_WaterDepth * linearEyeDepth);
	depth = 1.0 - depth;
	depth = lerp(depth, pow(depth, 3), 0.5);

	float4 resultColor = lerp(_DeepColor, _ShallowColor, depth);
	
	resultColor *= grabColor;

	//设置输出
	o.Normal = normal;
	o.Emission = resultColor.rgb;
	o.Albedo = resultColor.rgb * NdotV;
	o.Alpha = 1;

	o.Metallic = _Metallic;
	o.Smoothness = _Glossiness;
}
#endif