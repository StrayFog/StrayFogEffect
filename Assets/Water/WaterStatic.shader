Shader "Effect/Water/Water (Static)"
{
	Properties{
		_WaterTex("Normal Map (RGB), Foam (A)", 2D) = "white" {}
		_WaterColor("Color", COLOR) = (1,1,1,1)//( .34, .85, .92, 1)

		_ReflectionTex("Internal Reflection", 2D) = "" {}
		_RefractionTex("Internal Refraction", 2D) = "" {}
	}

	// -----------------------------------------------------------
	// Fragment program cards
	Subshader{
		Tags { "Queue" = "Transparent-10" }
		Pass {			
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest 
				//#pragma multi_compile WATER_REFLECTIVE WATER_REFRACTIVE
				#include "UnityCG.cginc"

				uniform sampler2D _ReflectionTex;
				uniform sampler2D _RefractionTex;

				uniform half _WaterDisplayMode;

				sampler2D _CameraDepthTexture;
				sampler2D _WaterTex;
				uniform float4 _WaterColor;

				struct v2f {
					float4 pos : SV_POSITION;
					float4 uv  : TEXCOORD0;
					float4 screenPos : TEXCOORD2;					
					float3 normal:NORMAL;
					float3 viewDir : NORMAL1;
				};

				v2f vert(appdata_base v)
				{
					v2f o;
					o.uv = v.texcoord;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.screenPos = ComputeScreenPos(o.pos);
					o.normal = v.normal;
					o.viewDir = ObjSpaceViewDir(v.vertex);		
					COMPUTE_EYEDEPTH(o.screenPos.z);
					return o;
				}

				half4 frag(v2f i) : COLOR
				{
					float4 color = tex2D(_WaterTex, i.uv) * _WaterColor;
					float4 refColor = float4(1, 1, 1, 1);
					float edgeDepth = 0;

					//通过深度纹理查询岸边与水里
					{//1-0 : 水里-岸边
						edgeDepth = tex2Dproj(_CameraDepthTexture, i.screenPos).r;
						edgeDepth = LinearEyeDepth(edgeDepth) - i.screenPos.z;
					}

					//计算反射与折射
					{
						float4 uv1 = i.screenPos;
						half4 refl = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(uv1));

						float4 uv2 = i.screenPos;
						half4 refr = tex2Dproj(_RefractionTex, UNITY_PROJ_COORD(uv2));

						float3 viewDir = normalize(i.viewDir);
						float fresnel = saturate(dot(viewDir, normalize(i.normal)));

						switch (_WaterDisplayMode)
						{
						case 0:
							refColor *= lerp(refl, refr, fresnel);
							break;
						case 1:
							refColor *= refl;
							break;
						case 2:
							refColor *= refr;
							break;
						}
					}
					
					//越离岸边越透明
					color.a *= saturate(edgeDepth);
					return color * refColor;
				}
				ENDCG
		}
	}
}