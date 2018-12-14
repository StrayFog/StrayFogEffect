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
float4 _ShalowColor;
float4 _DeepColor;
float4 _ShalowDeepFactor;

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
sampler2D _GrabTexture;
float4 _GrabTexture_TexelSize;

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
	half4 waterNoise = tex2D(_WaterNoise, IN.uv_WaterNoise + 
		RotationVector(float2(0, 1), _Time.x * _WaterSpeed));

	half2 uv_WaterNormal = IN.uv_WaterNormal;

	//Normal
	{
		float overlapAngle = _WaterOverlap  * sin(_Time.x + _WaterOverlap) * cos(_Time.x - _WaterOverlap) * 0.05;

		float2 flowDir1 = RotationVector(float2(0, 1), _WaterAngle + overlapAngle) * _WaterSpeed * _Time.x;
		float4 farSample1 = tex2D(_WaterNormal, uv_WaterNormal + flowDir1);
		float4 normalSample1 = tex2D(_WaterNormal, uv_WaterNormal + 
			flowDir1 * _Time.y * _WaterNormal_TexelSize.xy * _WaterSpeed +
			farSample1.xz * 0.05 * waterNoise.x);
		float3 normal1 = UnpackScaleNormal(normalSample1 * farSample1, _WaterNormalScale);

		float2 flowDir2 = RotationVector(float2(0, 1), _WaterAngle - overlapAngle) * _WaterSpeed * _Time.x;
		float4 farSample2 = tex2D(_WaterNormal, uv_WaterNormal + flowDir2);
		float4 normalSample2 = tex2D(_WaterNormal, uv_WaterNormal + 
			flowDir2 * _Time.y * _WaterNormal_TexelSize.xy * _WaterSpeed +
			farSample2.yw * 0.05 * waterNoise.x);
		float3 normal2 = UnpackScaleNormal(normalSample2* farSample2, _WaterNormalScale);

		o.Normal = BlendNormals(normal1, normal2);
	}
	
	float3 worldNormal = WorldNormalVector(IN, o.Normal);
	float3 worldView = UnityObjectToWorldDir(IN.viewDir);
	float3  worldLightDir = UnityWorldSpaceLightDir(IN.worldPos);

	//ambient
	float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

	//halfLambert
	half halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;
	//lambert
	half lambert = max(dot(worldNormal, worldLightDir), 0);

	//Water Color
	float4 waterColor = 0;
	{
		half depth = saturate(linearEyeDepth  *  _ShalowDeepFactor.x);
		depth = 1 - depth;
		depth = lerp(depth, pow(depth, _ShalowDeepFactor.y), waterNoise.x);
		waterColor = lerp(_DeepColor, _ShalowColor, depth);		
		
		waterColor.rgb *= lambert;
	}

	//GrabTexture Color
	float4 waterGrabColor = 0;
	{
		float4 grabUV = IN.screenPos;
		grabUV.xy += worldNormal.xz * _WaterRefraction * saturate(linearEyeDepth);// *_GrabTexture_TexelSize.xy *  _WaterRefraction;
		waterGrabColor = tex2Dproj(_GrabTexture, grabUV);
	}

	o.Emission = waterColor;
	o.Specular = _Specular;
	o.Smoothness = _Smoothness;
	o.Occlusion = _Occlusion;
	o.Alpha = waterColor.a;
}

/*
	float3 lightDirection = normalize(IN.worldPos - _WorldSpaceLightPos0);
	float3 halfDirection = normalize(worldView + lightDirection);
	float3 viewReflectDirection = reflect(-worldView, worldNormal);

	half NdotV = max(0, dot(worldNormal, worldView));
	half halfVL = max(0, dot(worldNormal, halfDirection));

	half worldViewFresnel = sqrt(1.0 - dot(-worldView, worldNormal));

	half factor = 0.5;
	float fresnel = factor + (1.0 - factor)*pow((dot(worldNormal, lightDirection)), 5);
	//fresnel = fresnel * (factor + (1.0 - factor)*pow((1.0 - NdotV), 5));
	//fresnel = saturate(max(fresnel, factor + (1.0 - factor)*pow((1.0 - NdotV), 5)));

	float4 resultColor = lerp(waterColor * waterGrabColor, waterGrabColor, fresnel);
	//Emission

	o.Emission = resultColor;*/