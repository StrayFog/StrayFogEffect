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
#endif