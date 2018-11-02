// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'defined WATER_REFLECTIVE' with 'defined (WATER_REFLECTIVE)'

Shader "Effect/Water/Water (Static)"
{
	Properties{
		_WaterTex("Main Tex", 2D) = "white" {}
		_WaterColor("Color", COLOR) = (1,1,1,1)
		_WaterNormal("Normal Tex", 2D) = "white" {}

		_ReflectionTex("Internal Reflection", 2D) = "white" {}
		_RefractionTex("Internal Refraction", 2D) = "white" {}
	}
	
	// -----------------------------------------------------------
	// Fragment program cards
	Subshader{
			Tags {"RenderType" = "Opaque" }
			Pass {
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest 
				#pragma multi_compile WATER_REFLECTIVE
				#pragma multi_compile WATER_REFRACTIVE
				#include "UnityCG.cginc"
				#include "Lighting.cginc"

				fixed4 _Diffuse;
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

				uniform sampler2D _ReflectionTex;
				uniform sampler2D _RefractionTex;

				struct v2f {
					float4 clipPos : SV_POSITION;
					float4 uv  : TEXCOORD0;
					float4 screenPos : TEXCOORD2;
					float4 wave:TEXCOORD3;

					float3 normal:NORMAL;
					float3 viewDir : NORMAL1;
				};

				//获得LinearEyeDepth深度差，差值代表从水到陆地的深度过度
				float GetLinearEyeDepthDiff(v2f i)
				{
					float depth = tex2Dproj(_CameraDepthTexture, i.screenPos).r;
					depth = LinearEyeDepth(depth);
					depth -= i.screenPos.z;
					return depth;
				}				

				v2f vert(appdata_full v)
				{
					v2f o;
					o.uv = v.texcoord;
					o.clipPos = UnityObjectToClipPos(v.vertex);
					o.screenPos = ComputeScreenPos(o.clipPos);					
					o.viewDir = ObjSpaceViewDir(v.vertex);
					o.normal = v.normal;
					COMPUTE_EYEDEPTH(o.screenPos.z);
#if UNITY_UV_STARTS_AT_TOP
					o.screenPos.y = (o.clipPos.w - o.clipPos.y) * 0.5;
#endif
					o.wave = v.vertex.xzxz * float4(1,1,1,1) / 1.0 + float4(0.1,0.2,0.3,0.4) * _Time.y * 0.1;

					return o;
				}

				half4 frag(v2f i) : SV_Target
				{
					half4 color = tex2D(_WaterTex, i.uv)*_WaterColor;
					
					half3 bump1 = UnpackNormal(tex2D(_WaterNormal, i.wave.xy)).rgb;
					half3 bump2 = UnpackNormal(tex2D(_WaterNormal, i.wave.zw)).rgb;
					half3 bump = (bump1 + bump2) * 0.5;

#if USE_REFLECTIVE
					float4 uv1 = i.screenPos;
					uv1.xy += bump;
					half4 refl = tex2Dproj(_ReflectionTex,UNITY_PROJ_COORD(uv1));
#endif

#if USE_REFRACTIVE
					float4 uv2 = i.screenPos;
					uv2.xy += bump;
					half4 refr = tex2Dproj(_RefractionTex, UNITY_PROJ_COORD(uv2));
#endif
					float3 viewDir = normalize(i.viewDir);
					float fresnel = saturate(dot(viewDir,normalize(i.normal)));

#if USE_REFLECTIVE && USE_REFRACTIVE
					color *= lerp(refl, refr, fresnel);
#elif USE_REFLECTIVE
					color *= refl;
#elif USE_REFRACTIVE
					color *= refr;
#endif
					float depth = GetLinearEyeDepthDiff(i);

					return color;
				}
				ENDCG
		}		
	}
}