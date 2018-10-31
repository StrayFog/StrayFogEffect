Shader "Effect/Water/Water (Static)"
{
	Properties{
		_WaterNormal("Normal Tex (RGB)", 2D) = "black" {}
		_WaterColor("Color", COLOR) = (1,1,1,1)//( .34, .85, .92, 1)

		_ReflectionTex("Internal Reflection", 2D) = "white" {}
		_RefractionTex("Internal Refraction", 2D) = "white" {}
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

				sampler2D _WaterNormal;
				float4 _WaterNormal_ST;

				uniform float4 _WaterColor;

				struct v2f {
					float4 clipPos : SV_POSITION;					
					float4 uv  : TEXCOORD0;
					float4 screenPos : TEXCOORD1;
					float3 worldPos:TEXCOORD2;
					float3 normal:NORMAL;
					float3 viewDir : NORMAL1;
				};

				v2f vert(appdata_base v)
				{
					v2f o;
					o.worldPos = v.vertex;
					o.uv = v.texcoord;
					o.clipPos = UnityObjectToClipPos(v.vertex);
					o.screenPos = ComputeScreenPos(o.clipPos);
					o.normal = v.normal;
					o.viewDir = ObjSpaceViewDir(v.vertex);
					COMPUTE_EYEDEPTH(o.screenPos.z);
					return o;
				}

				half4 frag(v2f i) : COLOR
				{
					float2 uv = i.uv* _WaterNormal_ST.xy + _WaterNormal_ST.zw;
					float offset = _Time.x *0.5;
					float4 normal = tex2D(_WaterNormal, uv+offset);

					float4 refColor = float4(1, 1, 1, 1);
					float edgeDepth = 0;

					//通过深度纹理查询岸边与水里
					{//1-0 : 水里-岸边
						edgeDepth = tex2Dproj(_CameraDepthTexture, i.screenPos).r;
						edgeDepth = LinearEyeDepth(edgeDepth) - i.screenPos.z;
					}

					float4 uvPos = i.screenPos + normal* edgeDepth;

					//计算反射与折射
					{
						float4 uv1 = uvPos;
						half4 refl = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(uv1));

						float4 uv2 = uvPos;
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

					float4 color = _WaterColor;
					color.a *= saturate(edgeDepth);
					return color * refColor;
				}
				ENDCG
		}
	}
}