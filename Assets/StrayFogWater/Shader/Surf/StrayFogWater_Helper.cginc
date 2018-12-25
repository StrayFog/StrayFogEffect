#ifndef STRAYFOGWATER_HELPER_INCLUDED
#define STRAYFOGWATER_HELPER_INCLUDED
//获得CameraDepthTexture的LinearEyeDepth
inline float StrayFogLinearEyeDepth(sampler2D _CameraDepthTexture, float4 _screenPos)
{
	return LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, _screenPos))) - _screenPos.w;
}

inline float4 OffsetUV(float4 uv, float2 offset) {
#ifdef UNITY_Z_0_FAR_FROM_CLIPSPACE
	uv.xy = offset * UNITY_Z_0_FAR_FROM_CLIPSPACE(uv.z) + uv.xy;
#else
	uv.xy = offset * uv.z + uv.xy;
#endif

	return uv;
}

inline float4 OffsetDepth(float4 uv, float2 offset) {
	uv.xy = offset * uv.z + uv.xy;
	return uv;
}

inline float texDepth(sampler2D_float _Depth, float4 uv) {
	return LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_Depth, UNITY_PROJ_COORD(uv)));
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

// =======================================================
// Displacement
// =======================================================

void Wave (out half3 offs, out half3 nrml, half3 vtx, half4 tileableVtx,half amplitude ,half frequency,half speed,half smoothing){

	float4 v0 = tileableVtx;
	float4 v1 = v0 + float4(0.05,0,0,0);
	float4 v2 = v0 + float4(0,0,0.05,0);

	float offSpeed = speed * _Time.y;
	amplitude *= 0.01;

	v0.y += sin (offSpeed + (v0.x * frequency )) * amplitude;
	v1.y += sin (offSpeed + (v1.x * frequency )) * amplitude;
	v2.y += sin (offSpeed + (v2.x * frequency )) * amplitude;

	v0.y -= cos (offSpeed + (v0.z * frequency )) * amplitude;
	v1.y -= cos (offSpeed + (v1.z * frequency )) * amplitude;
	v2.y -= cos (offSpeed + (v2.z * frequency )) * amplitude;

	v1.y -= (v1.y - v0.y) * (1 - smoothing);
	v2.y -= (v2.y - v0.y) * (1 - smoothing);

	float3 vna = cross(v2-v0,v1-v0);

	float4 vn 	= mul(float4x4(unity_WorldToObject), float4(vna,0) );
	nrml 		= normalize (vn).xyz;
	offs 		= mul(float4x4(unity_WorldToObject),v0).xyz;
}

half3 GerstnerNormal(half2 xzVtx, half4 amp, half4 freq, half4 speed, half4 dirAB, half4 dirCD, half smoothing)
{
	half3 nrml = half3(0, 2.0, 0);

	half4 AB = freq.xxyy * amp.xxyy * dirAB.xyzw;
	half4 CD = freq.zzww * amp.zzww * dirCD.xyzw;

	half4 dotABCD = freq.xyzw * half4(dot(dirAB.xy, xzVtx), dot(dirAB.zw, xzVtx), dot(dirCD.xy, xzVtx), dot(dirCD.zw, xzVtx));
	half4 TIME = _Time.yyyy * speed;

	half4 COS = cos(dotABCD + TIME);

	nrml.x -= dot(COS, half4(AB.xz, CD.xz));
	nrml.z -= dot(COS, half4(AB.yw, CD.yw));

	nrml.xz *= smoothing;
	nrml = normalize(nrml);

	return nrml;
}

half3 GerstnerOffset(half2 xzVtx, half steepness, half4 amp, half4 freq, half4 speed, half4 dirAB, half4 dirCD)
{
	half3 offsets;

	half4 AB = steepness * amp.xxyy * dirAB.xyzw;
	half4 CD = steepness * amp.zzww * dirCD.xyzw;

	half4 dotABCD = freq.xyzw * half4(dot(dirAB.xy, xzVtx), dot(dirAB.zw, xzVtx), dot(dirCD.xy, xzVtx), dot(dirCD.zw, xzVtx));
	half4 TIME = _Time.yyyy * speed;

	half4 COS = cos(dotABCD + TIME);
	half4 SIN = sin(dotABCD + TIME);

	offsets.x = dot(COS, half4(AB.xz, CD.xz));
	offsets.z = dot(COS, half4(AB.yw, CD.yw));
	offsets.y = dot(SIN, amp);

	return offsets;
}

void Gerstner(out half3 offs, out half3 nrml,
	half3 vtx, half3 tileableVtx,
	half4 amplitude, half4 frequency, half4 steepness,
	half4 speed, half4 directionAB, half4 directionCD, half smoothing)
{

	offs = GerstnerOffset(tileableVtx.xz, steepness, amplitude, frequency, speed, directionAB, directionCD);
	nrml = GerstnerNormal(tileableVtx.xz + offs.xz, amplitude, frequency, speed, directionAB, directionCD, smoothing);
}
#endif