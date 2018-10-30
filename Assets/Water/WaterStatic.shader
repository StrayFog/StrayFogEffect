// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Effect/Refraction/Refraction"
{
	Properties{
		_RefractionTex("Internal Refraction", 2D) = "" {}
		_RefrColor("Refraction color", COLOR) = (.34, .85, .92, 1)
	}

		// -----------------------------------------------------------
		// Fragment program cards
			Subshader{
					Tags {"WaterMode" = "Refractive" "RenderType" = "Opaque" }
					Pass {
						CGPROGRAM
						#pragma vertex vert
						#pragma fragment frag
						#include "UnityCG.cginc"

						struct appdata {
							float4 vertex : POSITION;
							float3 normal : NORMAL;
						};
						struct v2f {
							float4 pos : SV_POSITION;
							float4 ref : TEXCOORD0;
							float3 viewDir : TEXCOORD1;
						};

						v2f vert(appdata v)
						{
							v2f o;
							o.pos = UnityObjectToClipPos(v.vertex);
							o.viewDir.xzy = ObjSpaceViewDir(v.vertex);
							o.ref = ComputeScreenPos(o.pos);
							return o;
						}

						float4 _RefrColor;
						sampler2D _RefractionTex;
						half4 frag(v2f i) : COLOR
						{
							i.viewDir = normalize(i.viewDir);
							float4 uv2 = i.ref;
							half4 color = tex2Dproj(_RefractionTex,UNITY_PROJ_COORD(uv2)) * _RefrColor;
							return color;
						}
						ENDCG
				}
		}
}