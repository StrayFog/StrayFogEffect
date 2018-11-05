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
		Tags { "Queue" = "Transparent-10" }

		GrabPass
		{
			Name "BASE"
			Tags { "LightMode" = "Always" }
		}

		Blend Off
		ZTest LEqual
		ZWrite Off

		CGPROGRAM
		#pragma surface surf PPL vertex:vert noambient
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

		float Hash(float p)
		{
			float2 p2 = frac(float2(p, p) * float2(4.438975, 3.972973));
			p2 += dot(p2.yx, p2.xy + 19.19);
			return frac(p2.x * p2.y);
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


		void vert(inout appdata_full v, out Input o)
		{
			o.texcoord = v.texcoord;
			o.worldPos = v.vertex.xyz;
			o.position = UnityObjectToClipPos(v.vertex);
			o.screenPos0 = ComputeScreenPos(o.position);
			
			o.viewDir = ObjSpaceViewDir(v.vertex);
			o.normal = v.normal;

			COMPUTE_EYEDEPTH(o.screenPos0.z);
#if UNITY_UV_STARTS_AT_TOP
			o.screenPos0.y = (o.position.w - o.position.y) * 0.5;
#endif
		}

		void surf(Input IN, inout SurfaceOutput o)
		{
			half4 color = tex2D(_WaterTex, IN.texcoord) * _WaterColor;

			// Calculate the depth difference at the current pixel
			float depth = GetLinearEyeDepthDiff(IN);
			half3 bump = UnpackNormal(tex2D(_WaterNormal, IN.texcoord));
			
#if USE_REFLECTIVE
			float4 uv1 = IN.screenPos0;
			half4 refl = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(uv1));
#endif

#if USE_REFRACTIVE
			float4 uv2 = IN.screenPos0;
			half4 refr = tex2Dproj(_RefractionTex, UNITY_PROJ_COORD(uv2));
#endif
			float3 viewDir = normalize(IN.viewDir);
			float fresnel = saturate(dot(viewDir, normalize(IN.normal)));

#if USE_REFLECTIVE && USE_REFRACTIVE
			color = lerp(refl, refr, fresnel);
#elif USE_REFLECTIVE
			color = refl;
#elif USE_REFRACTIVE
			color = refr;
#endif
			o.Normal = bump;
			o.Albedo = color;
		}
		ENDCG
	}	
}