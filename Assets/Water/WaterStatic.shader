Shader "Effect/Water/Water (Static)" {
	Properties{
		_MainTex("Main Tex(RGB)", 2D) = "white" {}
		_Color("Main Color", Color) = (1,1,1,1)
		_BumpMap("Normalmap", 2D) = "bump" {}
		
		[Space(4)]
		[Header(Tessellate Settings ___________________________________________________)]
		[Space(4)]
		_EdgeLength("Edge length", Range(2, 50)) = 25
		_TessMaxDisp("Max Displacement", Float) = 20
		_TessPhongStrength("Phong Tess Strength", Range(0, 1)) = 0.5
		_TessHeightTex("Height Map", 2D) = "gray" {}
		_TessNormalMap("Normal Map", 2D) = "bump" {}
		_TessDisplacement("Displacement", Range(0, 1.0)) = 0.3

		[Space(4)]
		[Header(Reflection Settings ___________________________________________________)]
		[Space(4)]
		_ReflectionTex("Internal Reflection", 2D) = "white" {}

		[Space(4)]
		[Header(Refraction Settings ___________________________________________________)]
		[Space(4)]
		_RefractionTex("Internal Refraction", 2D) = "white" {}
	}

	SubShader{
			LOD 400
			Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
			Blend SrcAlpha OneMinusSrcAlpha
			

		CGPROGRAM
		#include "UnityCG.cginc"
		#include "Tessellation.cginc"

		#pragma surface surf StandardSpecular vertex:vert tessellate:tessFunction tessphong:_TessPhongStrength alpha:fade
		
#ifdef SHADER_API_D3D11
		#pragma target 4.0
#else
		#pragma target 3.0
#endif

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
		sampler2D _ReflectionTex;
		sampler2D _RefractionTex;

		sampler2D _MainTex;
		sampler2D _BumpMap;
		fixed4 _Color;

		float _EdgeLength;
		float _TessMaxDisp;
		float _TessPhongStrength;
		sampler2D _TessHeightTex;
		float _TessDisplacement;
		sampler2D _TessNormalMap;
		

		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;	
			float2 uv_TessNormalMap;
			float3 viewDir;
			float4 reflUV;
			float4 screenPos;
		};

		float4 tessFunction(appdata_full v0, appdata_full v1, appdata_full v2)
		{
			return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _EdgeLength, _TessMaxDisp);
		}
		void vert(inout appdata_full v)
		{
			float d = tex2Dlod(_TessHeightTex, float4(v.texcoord.xy, 0, 0)).r * _TessDisplacement;
			v.vertex.xyz += v.normal * d;
		}

		void surf(Input IN, inout SurfaceOutputStandardSpecular o) {
			half4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;

			float linearEyeDepth = 1;
			//linearEyeDepth 像素深度
			{
				linearEyeDepth = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, IN.screenPos))) - IN.screenPos.w;
			}
			linearEyeDepth = saturate(linearEyeDepth);

			//o.Emission = c.rgb;
			o.Albedo = c.rgb * linearEyeDepth;
			o.Specular = 0.2;
			o.Alpha = c.a;
			//o.Gloss = 1.0;
			o.Normal = UnpackNormal(tex2D(_TessNormalMap, IN.uv_TessNormalMap));
		}

		/*void vert(inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			float4 position = UnityObjectToClipPos(v.vertex);
			o.reflUV = ComputeScreenPos(position);
			COMPUTE_EYEDEPTH(o.reflUV.z);
#if UNITY_UV_STARTS_AT_TOP
			o.reflUV.y = (position.w - position.y) * 0.5;
#endif
		}

		void surf(Input IN, inout SurfaceOutputStandardSpecular o) {
			//像素深度
			float linearEyeDepth = 1;
			//折射与反射混合颜色
			fixed4 mixReflColor = fixed4(1, 1, 1, 1);

			//基础颜色
			fixed4 texColor = tex2D(_MainTex, IN.uv_MainTex) *_Color;
			
			//linearEyeDepth 像素深度
			{
				linearEyeDepth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, IN.reflUV).r) - IN.reflUV.z;
			}
			linearEyeDepth = saturate(linearEyeDepth);


			half3 bumpOffset = float3(1, 1, 1) / 1.0 + float3(0.2, 0.2, 0.2) * _Time.y * 0.1;
			half3 uvBumpMap = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap+ bumpOffset));
			uvBumpMap = uvBumpMap * 2 * 0.5;
			
			//法线
			//o.Normal = uvBumpMap;

			//折射与反射UV纹理偏移
			float4 reflUVOffset = IN.reflUV;
			reflUVOffset.xy += uvBumpMap.xy * linearEyeDepth;
			//折射与反射UV纹理
			float4 reflUV = reflUVOffset;
			
			//Refraction Reflection 获取折射与反射颜色
			{ 
#if USE_REFLECTIVE
				fixed4 reflcol = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(reflUV));
#endif

#if USE_REFRACTIVE
				fixed4 refrcol = tex2Dproj(_RefractionTex, UNITY_PROJ_COORD(reflUV));
#endif

				
#if USE_REFLECTIVE && USE_REFRACTIVE
				float3 viewDir = normalize(IN.viewDir);
				float mixReflFresnel = saturate(dot(viewDir, normalize(o.Normal)));
				mixReflColor = lerp(reflcol, refrcol, mixReflFresnel);
#elif USE_REFLECTIVE
				mixReflColor = reflcol;
#elif USE_REFRACTIVE
				mixReflColor = refrcol;
#endif
			}

			o.Emission = mixReflColor * texColor;
			o.Alpha = texColor.a;
		}
		*/
		ENDCG
	}
	FallBack "Standard"
}
