Shader "Effect/Water/Water (Static)"
{
	Properties{
		_WaterTex("Main Tex", 2D) = "white" {}
		_WaterColor("Color", COLOR) = (1,1,1,1)
		_WaterNormal("Normal Tex", 2D) = "white" {}


		_ReflectionTex("Internal Reflection", 2D) = "white" {}
		_RefractionTex("Internal Refraction", 2D) = "white" {}
	}

		CGINCLUDE
#ifdef SHADER_API_D3D11
#pragma target 4.0
#else
#pragma target 3.0
#endif
#include "UnityCG.cginc"
		half4 _Specular;

	half4 LightingPPL(SurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
	{
		half3 nNormal = normalize(s.Normal);
		half shininess = s.Gloss * 250.0 + 4.0;

#ifndef USING_DIRECTIONAL_LIGHT
		lightDir = normalize(lightDir);
#endif
		// Phong shading model
		half reflectiveFactor = max(0.0, dot(-viewDir, reflect(lightDir, nNormal)));

		// Blinn-Phong shading model
		//half reflectiveFactor = max(0.0, dot(nNormal, normalize(lightDir + viewDir)));

		half diffuseFactor = max(0.0, dot(nNormal, lightDir));
		half specularFactor = pow(reflectiveFactor, shininess) * s.Specular;

		half4 c;
		c.rgb = (s.Albedo * diffuseFactor + _Specular.rgb * specularFactor) * _LightColor0.rgb;
		c.rgb *= (atten * 2.0);
		c.a = s.Alpha;
		return c;
	}
	ENDCG

	SubShader
	{
		Lod 400
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "LightMode" = "ForwardBase"}
		Blend SrcAlpha OneMinusSrcAlpha
		CGPROGRAM
		#pragma surface surf PPL vertex:vert alpha:fade
		#pragma multi_compile WATER_REFLECTIVE
		#pragma multi_compile WATER_REFRACTIVE

#if defined (WATER_REFLECTIVE)
	#define USE_REFLECTIVE 1
#else
	#define USE_REFLECTIVE 0
#endif

#if defined (WATER_REFRACTIVE)
	#define USE_REFRACTIVE 1
#else
	#define USE_REFRACTIVE 0
#endif

		sampler2D _CameraDepthTexture;

		sampler2D _WaterTex;
		sampler2D _WaterNormal;
		float4 _WaterColor;

		sampler2D _ReflectionTex;
		sampler2D _RefractionTex;

		struct Input
		{
			float4 position  : POSITION;
			float4 texcoord : TEXCOORD0;
			float3 worldPos  : TEXCOORD2;	// Used to calculate the texture UVs and world view vector
			float4 screenPos0 	 : TEXCOORD3;	// Used for depth and reflection textures
			float3 ligthDir : TEXCOORD4;
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

		void vert(inout appdata_full v, out Input o)
		{
			o.texcoord = v.texcoord;
			o.worldPos = v.vertex.xyz;
			o.position = UnityObjectToClipPos(v.vertex);
			o.screenPos0 = ComputeScreenPos(o.position);

			o.viewDir = ObjSpaceViewDir(v.vertex);
			o.normal = v.normal;
			o.ligthDir = ObjSpaceLightDir(v.vertex);

			COMPUTE_EYEDEPTH(o.screenPos0.z);
#if UNITY_UV_STARTS_AT_TOP
			o.screenPos0.y = (o.position.w - o.position.y) * 0.5;
#endif
		}

		void surf(Input IN, inout SurfaceOutput o)
		{
			half4 outColor = tex2D(_WaterTex, IN.texcoord) * _WaterColor;
			// Calculate the depth difference at the current pixel
			float depth = saturate(GetLinearEyeDepthDiff(IN));

			float offset = sin(_Time.x);
			half3 bump = UnpackNormal((tex2D(_WaterNormal, IN.texcoord.xy + offset))) * depth;
			
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
			outColor *= lerp(refl, refr, fresnel);
#elif USE_REFLECTIVE
			outColor *= refl;
#elif USE_REFRACTIVE
			outColor *= refr;
#endif
			/*float r = max(0, dot(bump, IN.ligthDir));
			o.Albedo = lerp(float3(0,0,0),float3(1,1,1), r) * 10;			*/
			o.Emission = outColor;
			o.Alpha = depth;
		}
		ENDCG
	}
}