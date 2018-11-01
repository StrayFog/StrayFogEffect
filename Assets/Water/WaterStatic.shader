Shader "Effect/Water/Water (Static)"
{
	Properties{
		_WaterNormal("Normal Map (RGB), Foam (A)", 2D) = "white" {}
		_Color0("Shallow Color", Color) = (1,1,1,1)
		_Color1("Deep Color", Color) = (0,0,0,0)
		_Specular("Specular", Color) = (0,0,0,0)
		_Shininess("Shininess", Range(0.01, 1.0)) = 1.0
		_Tiling("Tiling", Range(0.025, 0.25)) = 0.25
		_ReflectionTint("Reflection Tint", Range(0.0, 1.0)) = 0.8
		_InvRanges("Inverse Alpha, Depth and Color ranges", Vector) = (1.0, 0.17, 0.17, 0.0)

		_FlowSpeed("Flow Speed", Float) = 0.3
		_WaveHeight("Wave Height", Float) = 0.1

		_ReflectionTex("Internal Reflection", 2D) = "white" {}
		_RefractionTex("Internal Refraction", 2D) = "white" {}
	}

		//==============================================================================================
		// Common functionality
		//==============================================================================================

		CGINCLUDE
#ifdef SHADER_API_D3D11
#pragma target 4.0
#else
#pragma target 3.0
#endif
#include "UnityCG.cginc"

	half4 _Color0;
	half4 _Color1;
	half4 _Specular;
	float _Shininess;
	float _Tiling;
	float _ReflectionTint;
	half4 _InvRanges;

	sampler2D _CameraDepthTexture;
	sampler2D _WaterNormal;

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

		sampler2D _ReflectionTex;
		sampler2D _RefractionTex;

		//uniform float4 _RefractionTex_ST;
		uniform float4 _RefractionTex_TexelSize;
		uniform float4 _WaterNormal_ST;

		uniform float _FlowSpeed, _WaveHeight;

		struct Input
		{
			float4 position  : POSITION;
			float3 worldPos  : TEXCOORD2;	// Used to calculate the texture UVs and world view vector
			float4 proj0   	 : TEXCOORD3;	// Used for depth and reflection textures
			float4 proj1	 : TEXCOORD4;	// Used for the refraction texture
		};

		//���LinearEyeDepth��Ȳ��ֵ�����ˮ��½�ص���ȹ���
		float GetLinearEyeDepthDiff(Input IN)
		{
			float depth = tex2Dproj(_CameraDepthTexture, IN.proj0).r;
			depth = LinearEyeDepth(depth);
			depth -= IN.proj0.z;
			return depth;
		}

		// Fast sincos
		float SmoothCurve(float x) {
			return x * x *(3.0 - 2.0 * x);
		}
		float TriangleWave(float x) {
			return abs(frac(x + 0.5) * 2.0 - 1.0);
		}
		float SmoothTriangleWave(float x) {
			return SmoothCurve(TriangleWave(x));
		}

		void vert(inout appdata_full v, out Input o)
		{
			float time = _Time.y * _FlowSpeed;
			float vhpos = v.vertex.x + v.vertex.z;
			float hoffset = SmoothTriangleWave(time + vhpos * 0.125);
			hoffset += SmoothTriangleWave(time + vhpos * 0.361);
			hoffset += SmoothTriangleWave(time + vhpos * 0.076);
			_WaveHeight = -abs(_WaveHeight);
			v.vertex.y += hoffset * _WaveHeight * _FlowSpeed;
			v.normal = mul((float3x3)unity_WorldToObject, float3(0, 1, 0));

			o.worldPos = v.vertex.xyz;
			o.position = UnityObjectToClipPos(v.vertex);
			o.proj0 = ComputeScreenPos(o.position);
			COMPUTE_EYEDEPTH(o.proj0.z);

			o.proj1 = o.proj0;
			#if UNITY_UV_STARTS_AT_TOP
			o.proj1.y = (o.position.w - o.position.y) * 0.5;
			#endif
		}

		void surf(Input IN, inout SurfaceOutput o)
		{
			// Calculate the world-space view direction (Y-up)
			// We can't use IN.viewDir because it takes the object's rotation into account, and the water should not.
			float3 worldView = (IN.worldPos - _WorldSpaceCameraPos);

			// Calculate the object-space normal (Z-up)
			float offset = _Time.x * 0.5;
			half2 tiling = IN.worldPos.xz * _Tiling;
			half4 nmap = (tex2D(_WaterNormal, tiling + offset) +
				tex2D(_WaterNormal, half2(-tiling.y, tiling.x) - offset)) * 0.5;
			o.Normal = nmap.xyz * 2.0 - 1.0;

			// World space normal (Y-up)
			half3 worldNormal = o.Normal.xzy;
			worldNormal.z = -worldNormal.z;

			// Calculate the depth difference at the current pixel
			float depth = GetLinearEyeDepthDiff(IN);

			// Calculate the depth ranges (X = Alpha, Y = Color Depth)
			half3 ranges = saturate(_InvRanges.xyz * depth);
			ranges.y = 1.0 - ranges.y;
			ranges.y = lerp(ranges.y, ranges.y * ranges.y * ranges.y, 0.5);

			// Calculate the color tint
			half4 col;
			col.rgb = lerp(_Color1.rgb, _Color0.rgb, ranges.y);
			col.a = ranges.x;

			// Initial material properties
			o.Alpha = col.a;
			o.Specular = col.a;
			o.Gloss = _Shininess;

			// Dot product for fresnel effect
			half fresnel = sqrt(1.0 - dot(-normalize(worldView), worldNormal));

			// High-quality reflection uses the dynamic reflection texture
			IN.proj0.xy += o.Normal.xy * 0.5;
			half3 reflection = tex2Dproj(_ReflectionTex, IN.proj0).rgb;
			reflection = lerp(reflection * col.rgb, reflection, fresnel * _ReflectionTint);
			

			// High-quality refraction uses the grab pass texture
			IN.proj1.xy += o.Normal.xy * _RefractionTex_TexelSize.xy * (20.0 * IN.proj1.z * col.a);
			half3 refraction = tex2Dproj(_RefractionTex, IN.proj1).rgb;
			refraction = lerp(refraction, refraction * col.rgb, ranges.z);

			// Color the refraction based on depth
			refraction = lerp(lerp(col.rgb, col.rgb * refraction, ranges.y), refraction, ranges.y);

			// The amount of foam added (35% of intensity so it's subtle)
			half foam = nmap.a * (1.0 - abs(col.a * 2.0 - 1.0)) * 0.20;

			// Always assume 20% reflection right off the bat, and make the fresnel fade out slower so there is more refraction overall
			fresnel *= fresnel * fresnel;
			fresnel = (0.8 * fresnel + 0.2) * col.a;

			// Calculate the initial material color
			o.Albedo = lerp(refraction, reflection, fresnel) + foam;

			// Calculate the amount of illumination that the pixel has received already
			// Foam is counted at 50% to make it more visible at night
			fresnel = min(1.0, fresnel + foam * 0.5);
			o.Emission = o.Albedo * (1.0 - fresnel);

			// Set the final color
		#ifdef USING_DIRECTIONAL_LIGHT
			o.Albedo *= fresnel;
		#else
			// Setting it directly using the equals operator causes the shader to be "optimized" and break
			o.Albedo = lerp(o.Albedo.r, 1.0, 1.0);
		#endif
		}
		ENDCG
	}
}