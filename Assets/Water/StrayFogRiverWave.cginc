#ifndef STRAYFOGRIVERWAVE_CG_INCLUDED
#define STRAYFOGRIVERWAVE_CG_INCLUDED

#define MOD2 float2(4.438975,3.972973);

float _EdgeLength;
float _TessMaxDisp;
float _TessPhongStrength;
sampler2D _WaterTesselation;
float4 _WaterTesselation_ST;
float _TessDisplacement;

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
half3 Lux_UnpackScaleNormal(half2 packednormal, half bumpScale)
{

	half3 normal;
	normal.xy = (packednormal.xy * 2 - 1);
#if (SHADER_TARGET >= 30)
	// SM2.0: instruction count limitation
	// SM2.0: normal scaler is not supported
	normal.xy *= bumpScale;
#endif
	normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
	return normal;

}

#pragma target 4.6

sampler2D _CameraDepthTexture;

sampler2D _GrabTex;
float4 _GrabTex_TexelSize;
sampler2D _WaterNormal;
float _WaterNormalScale;
float _WaterAngle;
float _WaterSpeed;

float _WaterDepth;
float4 _ShallowColor;
float4 _DeepColor;
float _RefractDistortion;

struct Input {
	half2 uv_WaterNormal;
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

//tessellate计算
float4 tessFunction(appdata_full v0, appdata_full v1, appdata_full v2)
{
	return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _EdgeLength, _TessMaxDisp);
}

void tessVert(inout appdata_full v)
{
	float d = tex2Dlod(_WaterTesselation, float4(v.texcoord.xy, 0, 0)).r * _TessDisplacement;
	v.vertex.xyz += v.normal * d;
}

void surf(Input IN, inout SurfaceOutputStandard o) {

	float3 eyeVec = normalize(IN.worldPos.xyz - _WorldSpaceCameraPos);
	float3 normal = UnpackScaleNormal(tex2D(_WaterNormal, IN.uv_WaterNormal), _WaterNormalScale);
	float3 worldNormal = WorldNormalVector(IN, normal);
	float3 lightDir = UnityWorldSpaceLightDir(IN.worldPos);
	
	float NdotV = max(0, dot(worldNormal, eyeVec));// 漫反射强度

	NdotV *= dot(reflect(lightDir, worldNormal), eyeVec);

	float4 grabUV = IN.screenPos;
	grabUV.xy += normal.xy;
	float4 grabColor = tex2Dproj(_GrabTex, grabUV);

	o.Normal = normal;
	o.Emission = grabColor.rgb * _ShallowColor.rgb;
	//o.Albedo = NdotV;
	o.Alpha = 1;
	//float linearEyeDepth = 1;
	////linearEyeDepth 像素深度
	//{
	//	linearEyeDepth = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, IN.screenPos))) - IN.screenPos.w;
	//}
	//linearEyeDepth = saturate(linearEyeDepth);

	////_WaterDirection
	//fixed2 offsetDirection = RotationVector(float2(0, 1), _WaterAngle);
	//float2 uv_WaterNormal = IN.uv_texcoord.xy * _WaterNormal_ST.xy + _WaterNormal_ST.zw;

	//fixed3 bump = UnpackNormal(tex2D(_WaterNormal, uv_WaterNormal + offsetDirection * _Time.yy * _WaterSpeed));

	////对屏幕图像的采样坐标进行偏移
	////选择使用切线空间下的法线方向来进行偏移是因为该空间下的法线可以反映顶点局部空间下的法线方向
	//fixed2 offset = bump * _RefractDistortion * _GrabTex_TexelSize;

	////对scrPos偏移后再透视除法得到真正的屏幕坐标
	//float4 uv = IN.screenPos + float4(offset, 0, 0) * saturate(linearEyeDepth);
	//half4 refractionColor = tex2Dproj(_GrabTex,UNITY_PROJ_COORD(uv / uv.w));

	////水深度颜色
	//half d = saturate(_WaterDepth * linearEyeDepth);
	//d = 1.0 - d;
	//d = lerp(d, pow(d, 3), 0.5);
	//half4 waterColor = lerp(_DeepColor, _ShallowColor, d);


	////o.Albedo = IN.vertexColor * linearEyeDepth; Emission
	////o.Albedo = waterColor;
	//o.Emission = waterColor * refractionColor * linearEyeDepth;
	//o.Alpha = linearEyeDepth;


	//o.Normal = UnpackNormal(tex2D(_TessNormalMap, IN.uv_TessNormalMap));
	// Metallic and smoothness come from slider variables
	o.Metallic = _Metallic;
	o.Smoothness = _Glossiness;
}
#endif