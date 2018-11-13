#ifndef STRAYFOGRIVERWAVE_CG_INCLUDED
#define STRAYFOGRIVERWAVE_CG_INCLUDED
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
float _WaterRefract;
float4 _Range;

half _Specular;
fixed _Gloss;

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
// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
UNITY_INSTANCING_BUFFER_START(Props)
// put more per-instance properties here
UNITY_INSTANCING_BUFFER_END(Props)

//fixed4 LightingWaterLight(SurfaceOutput s, fixed3 lightDir, half3 viewDir, fixed atten) {
//	half3 halfVector = normalize(lightDir + viewDir);
//	float diffFactor = max(0, dot(lightDir, s.Normal)) * 0.8 + 0.2;
//	float nh = max(0, dot(halfVector, s.Normal));
//	float spec = pow(nh, s.Specular * 128.0) * s.Gloss;
//	fixed4 c;
//	c.rgb = (s.Albedo * _LightColor0.rgb * diffFactor + _SpecColor.rgb * spec * _LightColor0.rgb) * (atten);
//	c.a = s.Alpha + spec * _SpecColor.a;
//	return c;
//}

float2 RotationVector(float2 vec, float angle)
{
	float radZ = radians(-angle);
	float sinZ, cosZ;
	sincos(radZ, sinZ, cosZ);
	return float2(vec.x * cosZ - vec.y * sinZ,
		vec.x * sinZ + vec.y * cosZ);
}

#define MOD2 float2(4.438975,3.972973);
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

float4 WaveOffset(float2 uv)
{
	float4 result = float4(uv,0,0);
	result.xy += RotationVector(float2(0, 1) * _Time.x * _WaterSpeed, _WaterAngle);
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
	float4 uv1 = WaveOffset(v.texcoord.xy);
	float4 uv2 = WaveOffset(float2(1 - v.texcoord.y, v.texcoord.x));
	float3 wave = ((tex2Dlod(_WaterTesselation, uv1) + tex2Dlod(_WaterTesselation, uv2)) * 0.5).rbg;
	v.vertex.xyz += v.normal * SmoothWave(wave) * _TessDisplacement;
}

void surf(Input IN, inout SurfaceOutputStandardSpecular o) {
	float linearEyeDepth = 1;
	//linearEyeDepth 像素深度
	{
		linearEyeDepth = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, IN.screenPos))) - IN.screenPos.w;
	}

	float4 waterNormal = (tex2D(_WaterNormal, WaveOffset(IN.uv_WaterNormal)) +
		tex2D(_WaterNormal, WaveOffset(float2(1 - IN.uv_WaterNormal.y, IN.uv_WaterNormal.x)))
		) / 2;	

	

	//水底纹理
	half3 offset = UnpackNormal(tex2D(_WaterNormal, WaveOffset(IN.uv_WaterNormal)));
	float4 grabUV = IN.screenPos;
	grabUV.xy += offset.xy * _WaterRefract * _GrabTex_TexelSize;
	float4 grabColor = tex2Dproj(_GrabTex, grabUV);

	/*float2 foamUV = IN.uv_WaterFoam;
	foamUV.xy += normal.xy * _WaterRefract * _GrabTex_TexelSize;
	float4 foamColor = tex2D(_WaterFoam, foamUV);*/

	//水深
	half deltaDepth = saturate(_WaterDepth * linearEyeDepth);
	deltaDepth = 1.0 - deltaDepth;
	deltaDepth = lerp(deltaDepth, pow(deltaDepth, 3), 0.5);

	float4 waterColor = lerp(_DeepColor, _ShallowColor, deltaDepth);

	//设置输出
	o.Normal = UnpackScaleNormal(waterNormal, _WaterNormalScale).xyz;

	o.Emission = grabColor * waterColor;
	o.Albedo = 0;

	o.Alpha = linearEyeDepth;
	o.Specular = _Specular;
	o.Smoothness = _Gloss;
	o.Occlusion = 1;
}
#endif