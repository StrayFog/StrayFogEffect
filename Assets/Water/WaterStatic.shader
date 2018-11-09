Shader "Effect/Water/Water (Static)"
{
	Properties{		
		_WaterNormal("Water Normal Map", 2D) = "bump" {}
		_WaterAngle("Water Angle",Range(0,360)) = 0
		_WaterSpeed("Water Speed",Range(0.01,1)) = 0.1
		_WaterDepth("Water Depth", Range(0 , 1)) = 0.17
		_ShallowColor("Shallow Color", Color) = (0.52,0.66,0.61,1)
		_DeepColor("Deep Color", Color) = (0.05,0.09,0.235,1)
		_RefractDistortion("Refract Distortion", Range(0, 1000)) = 100  //控制模拟折射时图像的扭曲程度

		[Space(4)]
		[Header(SurfaceOutput Settings ___________________________________________________)]
		[Space(4)]
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0

		[Space(4)]
		[Header(Tessellate Settings ___________________________________________________)]
		[Space(4)]
		_EdgeLength("Edge length", Range(2, 50)) = 25
		_TessMaxDisp("Max Displacement", Float) = 20
		_TessPhongStrength("Phong Tess Strength", Range(0, 1)) = 0.5
		_WaterTesselation("Water Tesselation", 2D) = "black" {}		
		_TessDisplacement("Displacement", Range(0, 1.0)) = 0.3


		//Test
		_UVVDirection1UDirection0("UV - V Direction (1) U Direction (0)", Int) = 0
		_WaterMixSpeed("Water Mix Speed", Vector) = (0.01,0.05,0,0)
		_WaterMainSpeed("Water Main Speed", Vector) = (1,1,0,0)
		_WaterTessScale("Water Tess Scale", Float) = 0.06
	}
		SubShader{
			Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
			Blend SrcAlpha OneMinusSrcAlpha
			GrabPass { "_GrabTex" }

			CGPROGRAM
			#include "UnityCG.cginc"
			#include "Tessellation.cginc"
			// Physically based Standard lighting model, and enable shadows on all light types
			#pragma surface surf Standard fullforwardshadows vertex:vert alpha:fade tessellate:tessFunction tessphong:_TessPhongStrength			

			// Use shader model 3.0 target, to get nicer looking lighting
			#pragma target 4.6

			sampler2D _CameraDepthTexture;

			sampler2D _GrabTex;
			float4 _GrabTex_TexelSize;
			sampler2D _WaterNormal;
			float4 _WaterNormal_ST;
			float _WaterAngle;
			float _WaterSpeed;

			float _WaterDepth;
			float4 _ShallowColor;
			float4 _DeepColor;
			float _RefractDistortion;

			float _EdgeLength;
			float _TessMaxDisp;
			float _TessPhongStrength;
			sampler2D _WaterTesselation;
			float4 _WaterTesselation_ST;
			float _TessDisplacement;

			//test
			uniform int _UVVDirection1UDirection0;
			uniform half2 _WaterMixSpeed;
			uniform half2 _WaterMainSpeed;
			uniform half _WaterTessScale;

			struct Input {
				half2 uv_texcoord;
				half2 uv4_texcoord4;
				float4 vertexColor : COLOR;
				float3 worldNormal;
				INTERNAL_DATA				
				float4 screenPos;
			};

			half _Glossiness;
			half _Metallic;


			// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
			// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
			// #pragma instancing_options assumeuniformscaling
			UNITY_INSTANCING_BUFFER_START(Props)
				// put more per-instance properties here
			UNITY_INSTANCING_BUFFER_END(Props)

			float2 RotationVector(float2 vec, float angle)
			{
				float radZ = radians(-angle);
				float sinZ, cosZ;
				sincos(radZ, sinZ, cosZ);
				return float2(vec.x * cosZ - vec.y * sinZ,
					vec.x * sinZ + vec.y * cosZ);
			}

			float4 tessFunction(appdata_full v0, appdata_full v1, appdata_full v2)
			{
				return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _EdgeLength, _TessMaxDisp);
			}

			void vert(inout appdata_full v)
			{
				float mulTime445 = _Time.y * 1;
				int Direction723 = _UVVDirection1UDirection0;
				float2 appendResult706 = (half2(_WaterMixSpeed.y, _WaterMixSpeed.x));
				float2 uv_WaterNormal = v.texcoord.xy * _WaterNormal_ST.xy + _WaterNormal_ST.zw;
				float2 panner612 = (uv_WaterNormal + mulTime445 * (((float)Direction723 == 1) ? _WaterMixSpeed : appendResult706));
				float2 WaterSpeedValueMix516 = panner612;
				float2 appendResult705 = (half2(_WaterMainSpeed.y, _WaterMainSpeed.x));
				float2 uv4_TexCoord829 = v.texcoord3.xy * float2(1, 1) + float2(0, 0);
				float2 appendResult823 = (half2(((((float)Direction723 == 1) ? _WaterMainSpeed : appendResult705).x * uv4_TexCoord829.x), ((((float)Direction723 == 1) ? _WaterMainSpeed : appendResult705).y * uv4_TexCoord829.y)));
				float mulTime815 = _Time.y * 0.3;
				float temp_output_816_0 = (mulTime815 * 0.15);
				float temp_output_818_0 = frac((temp_output_816_0 + 1));
				float2 temp_output_826_0 = (appendResult823 * temp_output_818_0);
				float2 WaterSpeedValueMainFlowUV1830 = (uv_WaterNormal + temp_output_826_0);
				float2 temp_output_825_0 = (appendResult823 * frac((temp_output_816_0 + 0.5)));
				float2 WaterSpeedValueMainFlowUV2831 = (uv_WaterNormal + temp_output_825_0);
				float clampResult845 = clamp(abs(((temp_output_818_0 + -0.5) * 2)), 0, 1);
				float SlowFlowHeightBase835 = clampResult845;
				float lerpResult840 = lerp(tex2Dlod(_WaterTesselation, half4(WaterSpeedValueMainFlowUV1830, 0, 1)).g, tex2Dlod(_WaterTesselation, half4(WaterSpeedValueMainFlowUV2831, 0, 1)).r, SlowFlowHeightBase835);
				float3 ase_vertexNormal = v.normal.xyz;
				v.vertex.xyz += (((_WaterTessScale * tex2Dlod(_WaterTesselation, half4(WaterSpeedValueMix516, 0, 1)).r) + (_WaterTessScale * lerpResult840)) * ase_vertexNormal);
			}

			void surf(Input IN, inout SurfaceOutputStandard o) {
				float linearEyeDepth = 1;
				//linearEyeDepth 像素深度
				{
					linearEyeDepth = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, IN.screenPos))) - IN.screenPos.w;
				}

				////_WaterDirection
				//fixed2 offsetDirection = RotationVector(float2(0, 1), _WaterAngle);
				//float2 uv_WaterNormal = IN.uv_texcoord.xy * _WaterNormal_ST.xy + _WaterNormal_ST.zw;
				//fixed3 bump = UnpackNormal(tex2D(_WaterNormal, uv_WaterNormal + offsetDirection * _Time.yy * _WaterSpeed));
				//
				////对屏幕图像的采样坐标进行偏移
				////选择使用切线空间下的法线方向来进行偏移是因为该空间下的法线可以反映顶点局部空间下的法线方向
				//fixed2 offset = bump * _RefractDistortion * _GrabTex_TexelSize;

				////对scrPos偏移后再透视除法得到真正的屏幕坐标
				//float4 uv = IN.screenPos + float4(offset, 0, 0) * saturate(linearEyeDepth);
				//half4 refractionColor = tex2Dproj(_GrabTex,UNITY_PROJ_COORD(uv / uv.w));

				//水深度颜色
				half d = saturate(_WaterDepth * linearEyeDepth);
				d = 1.0 - d;
				d = lerp(d, pow(d, 3), 0.5);
				half4 waterColor = lerp(_DeepColor, _ShallowColor, d);
								
				o.Albedo = waterColor * saturate(linearEyeDepth);				
				o.Alpha = waterColor.a;

				// Metallic and smoothness come from slider variables
				o.Metallic = _Metallic;
				o.Smoothness = _Glossiness;
			}
			ENDCG
		}
			FallBack "Diffuse"
}