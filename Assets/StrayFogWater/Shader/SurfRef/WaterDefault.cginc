#ifndef UNITY_CG_INCLUDED
#define UNITY_CG_INCLUDED
sampler2D _CameraDepthTexture;
sampler2D _WaterTex;
sampler2D _WaterNormal;
float4 _WaterNormal_ST;
float4 _WaterColor;
float _WaterNormalDistort;
int _WaterNormalSmooth;
float4 _WaterWaveScale;
float4 _WaterWaveOffset;
float _WaterWaveSpeed;
sampler2D _ReflectionTex;
sampler2D _RefractionTex;

struct Input
{
	float4 position  : POSITION;
	float4 texcoord : TEXCOORD0;
	float3 worldPos  : TEXCOORD2;	// Used to calculate the texture UVs and world view vector
	float4 screenPos0 	 : TEXCOORD3;	// Used for depth and reflection textures
	float4 wave:TEXCOORD4;
	float3 normal:NORMAL;
	float3 viewDir : NORMAL1;
};

//获得LinearEyeDepth深度差，差值代表从水到陆地的深度过度
float GetLinearEyeDepthDiff(Input IN)
{
	float depth = tex2Dproj(_CameraDepthTexture, IN.screenPos0).r;
	depth = LinearEyeDepth(depth);
	depth -= IN.screenPos0.z;
	return depth;
}

void WaterDefultVert(inout appdata_full v, out Input o)
{
	o.texcoord = v.texcoord;
	o.worldPos = v.vertex.xyz;
	o.position = UnityObjectToClipPos(v.vertex);
	o.screenPos0 = ComputeScreenPos(o.position);

	o.viewDir = ObjSpaceViewDir(v.vertex);
	o.normal = v.normal;

	o.wave = (v.vertex.xzxz * _WaterNormal_ST.xyxy + _WaterNormal_ST.zwzw) * _WaterWaveScale / 1.0 + _WaterWaveOffset * _Time.y * _WaterWaveSpeed;
	COMPUTE_EYEDEPTH(o.screenPos0.z);
#if UNITY_UV_STARTS_AT_TOP
	o.screenPos0.y = (o.position.w - o.position.y) * 0.5;
#endif
}

void WaterDefaultSurf(Input IN,inout SurfaceOutput o)
{
	half4 outColor = tex2D(_WaterTex, IN.texcoord) * _WaterColor;
	// Calculate the depth difference at the current pixel
	float depth = saturate(GetLinearEyeDepthDiff(IN));

	float offset = _Time.x;
	half3 bump = half3(0, 0, 0);
	for (int i = 0; i < _WaterNormalSmooth; i++)
	{
		bump += UnpackNormal(tex2D(_WaterNormal, IN.wave.xy)).rgb * _WaterNormalDistort;
	}
	o.Normal = bump;
#if USE_REFLECTIVE
	float4 uv1 = IN.screenPos0;
	uv1.xy += bump.xy;
	half4 refl = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(uv1));
#endif

#if USE_REFRACTIVE
	float4 uv2 = IN.screenPos0;
	uv2.xy += bump.xy;
	half4 refr = tex2Dproj(_RefractionTex, UNITY_PROJ_COORD(uv2));
#endif
	float3 viewDir = normalize(IN.viewDir);
	float fresnel = saturate(dot(viewDir, normalize(IN.normal)));

#if USE_REFLECTIVE && USE_REFRACTIVE
	outColor = lerp(refl, refr, fresnel);
#elif USE_REFLECTIVE
	outColor = refl;
#elif USE_REFRACTIVE
	outColor = refr;
#endif
	float3 edgeColor = lerp(float3(1, 0, 0), float3(0, 0, 0), depth);
	o.Emission = outColor + edgeColor;
	o.Alpha = depth;
}