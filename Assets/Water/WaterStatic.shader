Shader "Effect/Water/Water (Static)"
{
	Properties{
		_WaterNormal("Normal Map (RGB), Foam (A)", 2D) = "white" {}
		_RefractDistortion("Refract Distortion", Range(0, 1000)) = 100  //����ģ������ʱͼ���Ť���̶�
		_RefractRatio("Refract Ratio",Range(0.1,1)) = 0.5 //����ģ��������
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
						//�õ���Ӧ��ץȡ����Ļͼ��Ĳ�������
						o.scrPos = ComputeGrabScreenPos(o.pos);
						COMPUTE_EYEDEPTH(o.scrPos.z);

						o.uv.xy = TRANSFORM_TEX(v.texcoord, _WaterNormal);

						float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
						fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
						fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
						fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;						

						//���߿ռ䵽����ռ�ı任����
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
						
						//linearEyeDepth �������
						float linearEyeDepth = 1;
						{
							linearEyeDepth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, i.scrPos).r) - i.scrPos.z;
						}
						linearEyeDepth = saturate(linearEyeDepth);

						//����Ļͼ��Ĳ����������ƫ��
						//ѡ��ʹ�����߿ռ��µķ��߷���������ƫ������Ϊ�ÿռ��µķ��߿��Է�ӳ����ֲ��ռ��µķ��߷���
						fixed2 offset = bump * _RefractDistortion * _RefractionTex_TexelSize;
						//��scrPosƫ�ƺ���͸�ӳ����õ���������Ļ����
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