Shader "Effect/Water/Water (Static)"
{
	Properties{
		_WaterNormal("Normal Map (RGB), Foam (A)", 2D) = "white" {}
		_RefractDistortion("Refract Distortion", Range(0, 1000)) = 100  //控制模拟折射时图像的扭曲程度
		_RefractRatio("Refract Ratio",Range(0.1,1)) = 0.5 //控制模拟折射率
	}

		// -----------------------------------------------------------
		// Fragment program cards
			Subshader{
				Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
				Blend SrcAlpha OneMinusSrcAlpha
				
				GrabPass { "_RefractionTex" }
				Pass {
					CGPROGRAM
					#pragma 4.6
					#pragma vertex vert
					#pragma fragment frag
					#pragma fragmentoption ARB_precision_hint_fastest 
					#include "UnityCG.cginc"					

					sampler2D _CameraDepthTexture;

					sampler2D _RefractionTex;
					float4 _RefractionTex_TexelSize;

					sampler2D _WaterNormal;
					float4 _WaterNormal_ST;

					float _RefractDistortion;
					float _RefractRatio;

					struct v2f {
						float4 pos : SV_POSITION;
						float4 scrPos : TEXCOORD0;
						float4 uv : TEXCOORD1;
						float4 TtoW0 : TEXCOORD2;
						float4 TtoW1 : TEXCOORD3;
						float4 TtoW2 : TEXCOORD4;
					};

					v2f vert(appdata_full v)
					{
						v2f o;
						o.pos = UnityObjectToClipPos(v.vertex);
						//得到对应被抓取的屏幕图像的采样坐标
						o.scrPos = ComputeGrabScreenPos(o.pos);
						COMPUTE_EYEDEPTH(o.scrPos.z);

						o.uv.xy = TRANSFORM_TEX(v.texcoord, _WaterNormal);

						float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
						fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
						fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
						fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;						

						//切线空间到世界空间的变换矩阵
						o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
						o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
						o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
						return o;
					}

					half4 frag(v2f i) : COLOR
					{
						float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
						fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

						fixed3 bump = UnpackNormal(tex2D(_WaterNormal, i.uv.xy));
						fixed3 worldNormal = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
						
						//linearEyeDepth 像素深度
						float linearEyeDepth = 1;
						{
							linearEyeDepth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, i.scrPos).r) - i.scrPos.z;
						}
						linearEyeDepth = saturate(linearEyeDepth);

						//对屏幕图像的采样坐标进行偏移
						//选择使用切线空间下的法线方向来进行偏移是因为该空间下的法线可以反映顶点局部空间下的法线方向
						fixed2 offset = bump * _RefractDistortion * _RefractionTex_TexelSize;
						//对scrPos偏移后再透视除法得到真正的屏幕坐标
						float4 uv = i.scrPos + float4(offset,0,0) * linearEyeDepth;// / ;

						half4 refraction = tex2Dproj(_RefractionTex, UNITY_PROJ_COORD(uv/ i.scrPos.w));

						refraction *= linearEyeDepth;
						refraction.a = 1;
						return refraction;
					}
					ENDCG
			}
		}
}