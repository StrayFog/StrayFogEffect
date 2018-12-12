#pragma target 4.6
#include "StrayFogCameraDepthTexture.cginc"
#include "StrayFogRiver.cginc"
//Water
sampler2D _WaterNormal;
float4 _WaterNormal_TexelSize;
float _WaterNormalScale;
float _WaterAngle;
float _WaterOverlap;
float _WaterSpeed;
float _WaterRefraction;

//Water Foam
sampler2D _WaterFoam;

//Water Noise
sampler2D _WaterNoise;

//Tessellate Mesh
float _TessEdgeLength;
float _TessMaxDisp;
float _TessPhongStrength;

//Water
sampler2D _CameraDepthTexture;
sampler2D _GrabTex;
float4 _GrabTex_TexelSize;

//Light
float4 _Specular;
half _Smoothness;
half _Occlusion;

struct Input {
	half2 uv_WaterNormal;
	half2 uv_WaterFoam;
	half2 uv_WaterNoise;
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
}

//SurfaceOutputStandardSpecular
void tessSurf(Input IN, inout SurfaceOutputStandardSpecular o) {
	//linearEyeDepth 像素深度
	float linearEyeDepth = StrayFogLinearEyeDepth(_CameraDepthTexture, IN.screenPos);

	half4 waterFoam = tex2D(_WaterFoam, IN.uv_WaterFoam);
	half4 waterNoise = tex2D(_WaterNoise, IN.uv_WaterNoise);

	half2 uv_WaterNormal = IN.uv_WaterNormal;

	float2 flowDir1 = RotationVector(float2(0, 1), _WaterAngle + _WaterOverlap) * _WaterSpeed * _Time.x;
	float4 farSample1 = tex2D(_WaterNormal, uv_WaterNormal + flowDir1);
	float4 normalSample1 = tex2D(_WaterNormal, uv_WaterNormal + farSample1.xz * 0.05);
	float3 normal1 = UnpackScaleNormal(normalSample1, _WaterNormalScale);

	float2 flowDir2 = RotationVector(float2(0, 1), _WaterAngle - _WaterOverlap) * _WaterSpeed * _Time.x;
	float4 farSample2 = tex2D(_WaterNormal, uv_WaterNormal + flowDir2);
	float4 normalSample2 = tex2D(_WaterNormal, uv_WaterNormal + farSample2.yw * 0.05);
	float3 normal2 = UnpackScaleNormal(normalSample2, _WaterNormalScale);

	o.Normal = lerp(normal1, normal2, waterNoise.r);
	o.Emission = lerp(normalSample1, normalSample2, waterNoise.r);

	/*
	float2 offsetFactor = _GrabTexture_TexelSize.xy * _Refraction * perspectiveFadeFactor * edgeBlendFactor;			
	float2 offset = worldNormal.xz * offsetFactor;
	float4 distortedGrabUVs = IN.grabUV;
	distortedGrabUVs.xy += offset;
	*/

	/*
	//uv_WaterNormal += TimeNoiseFBM(_WaterNoise,uv_WaterNormal,_Time.x)*_WaterSpeed;
	
	float2 flowDir1 = RotationVector(float2(0, 1), _WaterAngle + _WaterOverlap);
	float2 flowDir2 = RotationVector(float2(0, 1), _WaterAngle - _WaterOverlap);
	
	float2 norUV1 = uv_WaterNormal + flowDir1 * _Time.x * _WaterSpeed;
	float2 norUV2 = uv_WaterNormal + flowDir2 * _Time.x * _WaterSpeed;

	float3 normal1 = UnpackScaleNormal(tex2D(_WaterNormal, norUV1), _WaterNormalScale);
	float3 normal2 = UnpackScaleNormal(tex2D(_WaterNormal, norUV2), _WaterNormalScale);

	o.Normal = lerp(normal1, normal2, waterNoise.r);*/

	
	/*float3 worldView = normalize(_WorldSpaceCameraPos.xyz - IN.worldPos);
	float3 worldNormal = WorldNormalVector(IN, o.Normal);

	
	float3 lightDirection = normalize(_WorldSpaceLightPos0 - IN.worldPos);
	float3 viewReflectDirection = reflect(-worldView, worldNormal);


	half fresnelTerm = 1.0 - saturate(dot(viewReflectDirection, lightDirection));

	float _Specularity = 0.3;
	float _SpecPower = 1;
	half specular = pow(max(dot(viewReflectDirection, lightDirection), 0.0), 250.0 * _Specularity) * _SpecPower;

	fresnelTerm = saturate(dot(worldView, viewReflectDirection));	
	o.Emission = fresnelTerm ;*/

	//lerp(float3 (.025, .2, .125), float3(0.196, 0.262, 0.196), fresnelTerm*0.6) + 

	//o.Emission = float3 (.025, .2, .125) * dot(viewReflectDirection, lightDirection) * 5;

	/*float2 uv_Forward =  normalize(RotationVector(float2(0, 1), _WaterAngle));	

	uv_WaterNormal += uv_Forward * _Time.x * _WaterSpeed;
	o.Emission = tex2D(_WaterNormal, uv_WaterNormal); */
	
	// UnpackScaleNormal(tex2D(_WaterNormal, uv_WaterNormal), _WaterNormalScale);
	
	/*half4 noiseXY = tex2D(_WaterNoise, IN.uv_WaterNoise);
	o.Emission = noiseXY.rgb;*/
	/*uv_WaterNormal = IN.uv_WaterNormal + uv_ForwardA * _Time.x * _WaterSpeed;
	float3 nor1 = UnpackScaleNormal(tex2D(_WaterNormal, uv_WaterNormal), _WaterNormalScale);

	uv_WaterNormal = IN.uv_WaterNormal + uv_ForwardB * _Time.x * _WaterSpeed;
	float3 nor2 = UnpackScaleNormal(tex2D(_WaterNormal, uv_WaterNormal), _WaterNormalScale);
	
	o.Normal = (nor1 + nor2) * 0.5;
	float angle = dot(o.Normal, normalize(IN.viewDir));
	angle = 0.95 - 0.6*angle*angle;*/
	//o.Emission = angle;

	//float offset = tex2D(_WaterNoise, IN.uv_WaterNoise).b;

	/*uv_WaterNormal = lerp(uv_WaterNormal, uv_WaterNormal	+ _Time.x * 0.02,_Time.x * 0.02);

	half4 noiseXY = tex2D(_WaterNoise, IN.uv_WaterNoise);
	
	uv_WaterNormal = map(uv_WaterNormal, _WaterNormalScale);
	float3 ori = UnpackScaleNormal(tex2D(_WaterNormal, uv_WaterNormal), _WaterNormalScale);
	o.Normal = ori;	*/
	
	//o.Emission =tex2D(_WaterFoam, IN.uv_WaterFoam);

	/*fixed3 ori = UnpackScaleNormal(tex2D(_WaterNormal, uv_WaterNormal 
		+ _Time.y * _WaterNormal_TexelSize.xy - _WaterNormal_TexelSize.xy), _WaterNormalScale);

	fixed3 ori_ddy = UnpackScaleNormal(tex2D(_WaterNormal, uv_WaterNormal 
		+ _Time.y * _WaterNormal_TexelSize.xy * 3),_WaterNormalScale);

	o.Normal += lerp(ori,ori_ddy, abs(sin(_Time.y)));*/

	//o.Normal += lerp(ori,ddxyOri,sin(_Time.y));
	//SmoothNoise(normalSample.xy)
	
	//float3 vResult = 0;
	//float fTot = 0;
	//float g_fTime = _Time.x;
	//float fBaseTime = 0;

	//for (int i = 0; i < 3; i++)
	//{
	//	g_fTime = fBaseTime + (fTot / 10.0) / 30.0;
	//	//vec3 vCurrRayDir = vRayDir;
	//	float3 vRandom = float3(SmoothNoise(uv_WaterNormal.xy + fTot),
	//		SmoothNoise(uv_WaterNormal.yx + fTot + 42.0),
	//		SmoothNoise(uv_WaterNormal.xx + uv_WaterNormal.yy + fTot + 42.0)) * 2.0 - 1.0;
	//	vRandom = normalize(vRandom);
	//	o.Normal += vRandom;
	//	/*vCurrRayDir += vRandom * 0.001;
	//	vCurrRayDir = normalize(vCurrRayDir);
	//	vResult += GetSceneColour(vRayOrigin, vCurrRayDir);*/
	//	fTot += 1.0;
	//}
	////vResult /= fTot;
	//o.Normal /= fTot;
	/*fixed4 normalSample = tex2D(_WaterNormal, uv_WaterNormal);

	o.Normal = Tonemap(UnpackScaleNormal(normalSample, _WaterNormalScale));*/
	
	/*
	float4 _FarBumpSampleParams = float4(0.25, 0.01, 0, 0);
	float2 _FinalBumpSpeed01 = RotationVector(float2(0, 1), _WaterAngle + 10).xy * _WaterSpeed;

	fixed4 farSample = tex2D(_WaterNormal,
		FBM(uv_WaterNormal, 0.5) +
		_Time.x * _FinalBumpSpeed01 * _FarBumpSampleParams.x);

	fixed4 normalSample = tex2D(_WaterNormal, FBM(uv_WaterNormal, 0.5) + farSample.rg * 0.05);
	normalSample = lerp(normalSample, farSample, saturate(linearEyeDepth * _FarBumpSampleParams.y));

	o.Normal = UnpackScaleNormal(normalSample, _WaterNormalScale);*/

	//o.Normal = UnpackScaleNormal(tex2D(_WaterNormal,FBM(uv_WaterNormal, 0.5)), _WaterNormalScale);

	/*float t = _Time.x / 4;
	float2 uv_WaterNormal = IN.uv_WaterNormal;
	uv_WaterNormal += t * 0.2;
	float4 c1 = tex2D(_WaterNormal, uv_WaterNormal);
	uv_WaterNormal += t * 0.3;
	float4 c2 = tex2D(_WaterNormal, uv_WaterNormal);
	uv_WaterNormal += t * 0.4;
	float4 c3 = tex2D(_WaterNormal, uv_WaterNormal);
	c1 += c2 - c3;
	float4 normal = (c1.x + c1.y + c1.z) / 3;

	o.Normal = UnpackNormal(normal).xyz;*/

	/*half fresnelFac = saturate(dot(IN.viewDir, o.Normal));

	float4 grabUV = IN.screenPos;
	grabUV.xy += o.Normal.xz * _GrabTex_TexelSize.xy * _WaterRefraction;
	grabUV.xy /= grabUV.w;
	float4 waterGrabColor = tex2Dproj(_GrabTex, grabUV);*/

	//o.Emission = lerp(waterGrabColor *0.5,waterGrabColor, fresnelFac);




	//half fresnel = sqrt(1.0 - dot(-normalize(IN.viewDir), o.Normal));


	/*float4 _FarBumpSampleParams = float4(0.25, 0.01, 0, 0);
	float2 _FinalBumpSpeed01 = RotationVector(float2(0, 1), _WaterAngle + 10).xy * _WaterSpeed;
	half2 uv_WaterNormal = IN.uv_WaterNormal;

	fixed4 farSample = tex2D(_WaterNormal,
		uv_WaterNormal +
		_Time.x * _FinalBumpSpeed01 * _FarBumpSampleParams.x);

	fixed4 normalSample = tex2D(_WaterNormal, uv_WaterNormal + farSample.rg * 0.05);
	normalSample = lerp(normalSample, farSample,saturate(linearEyeDepth * _FarBumpSampleParams.y));

	fixed3 lerp_WaterNormal = UnpackScaleNormal(normalSample,_WaterNormalScale);
	o.Normal = lerp_WaterNormal;*/

	//float4 grabUV = IN.screenPos;	
	//grabUV.xy += o.Normal.xz * _WaterRefraction;
	//grabUV.xy += o.Normal.xz * _GrabTex_TexelSize.xy * _WaterRefraction;

	//float4 waterGrabColor = tex2D(_GrabTex, grabUV);

	//half range = saturate(_WaterDepth * linearEyeDepth);
	//range = 1.0 - range;
	//range = lerp(range, pow(range,3), 0.5);

	//// Calculate the color tint
	//half4 waterColor= lerp(_WaterDeepColor, _WaterShallowColor, range);

	//o.Normal = GerstNormal(uv_WaterNormal);
	//o.Emission = UnpackNormal(tex2D(_WaterNormal, GerstNormal(uv_WaterNormal)));

	//o.Emission = lerp(waterGrabColor, waterGrabColor*0.6, saturate(fresnel));

	/*uv_WaterNormal = 0.5 - uv_WaterNormal;
	float color = 3.0 - (3.*length(2.* uv_WaterNormal));

	float3 coord = float3(atan(uv_WaterNormal.y / uv_WaterNormal.x) / 6.2832 + .5, length(uv_WaterNormal)*.4, .5);

	for (int i = 1; i <= 7; i++)
	{
		float power = pow(2.0, float(i));
		color += (1.5 / power) * snoise(coord + float3(0., -iTime * .05, iTime*.01), power*16.);
	}
	o.Emission = float3(color, pow(max(color, 0.), 2.)*0.4, pow(max(color, 0.), 3.)*0.15);*/

	o.Specular = _Specular;
	o.Smoothness = _Smoothness;
	o.Occlusion = _Occlusion;
	o.Alpha = 1;
}