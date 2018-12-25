#ifndef STRAYFOGWATER_HELPER_INCLUDED
#define STRAYFOGWATER_HELPER_INCLUDED
//获得CameraDepthTexture的LinearEyeDepth
inline float StrayFogLinearEyeDepth(sampler2D _CameraDepthTexture,float4 _screenPos)
{
	return LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, _screenPos))) - _screenPos.w;
}
// =======================================================
// StrayFogRotateAround
// =======================================================
float2 StrayFogRotateAround(float2 vec, float angle)
{
	float radZ = radians(-angle);
	float sinZ, cosZ;
	sincos(radZ, sinZ, cosZ);
	return normalize(float2(vec.x * cosZ - vec.y * sinZ,
		vec.x * sinZ + vec.y * cosZ));
}

// expects first normal to be unpacked already
half3 UnpackAndBlendNormals(fixed3 n1, fixed4 n2, fixed4 n3,float4 bumpScale) {
	half3 normal;
#if defined(UNITY_NO_DXT5nm)
	normal = normalize(n1 + (n2.xyz * 2 - 1) + (n3.xyz * 2 - 1));
#else
	normal.xy = n1.xy;
	normal.xy += (n2.ag * 2 - 1) * bumpScale.y;
	normal.xy += (n3.ag * 2 - 1) * bumpScale.z;
	normal.z = sqrt(1.0 - saturate(normal.x * normal.x + normal.y * normal.y));
	normal = normalize(normal);
#endif
	return normal;
}

float2 rotate2D(float2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	float2x2 m = float2x2(c, -s, s, c);
	return mul(m, v);
}
#endif