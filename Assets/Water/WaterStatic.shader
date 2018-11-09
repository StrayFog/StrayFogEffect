// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Effect/Water/Water (Static)"
{
	Properties{
		_WaterNormal("Water Normal Map (RGB), Foam (A)", 2D) = "white" {}
		_WaterAngle("Water Angle",Range(0,360)) = 0
		_WaterSpeed("Water Speed",Range(0.01,1)) = 0.1
		_WaterDepth("Water Depth", Range(0 , 1)) = 0.17
		_ShallowColor("Shallow Color", Color) = (0.52,0.66,0.61,1)
		_DeepColor("Deep Color", Color) = (0.05,0.09,0.235,1)
		_RefractDistortion("Refract Distortion", Range(0, 1000)) = 100  //控制模拟折射时图像的扭曲程度

		[Space(4)]
		[Header(Tessellate Settings ___________________________________________________)]
		[Space(4)]
		_EdgeLength("Edge length", Range(2, 50)) = 25
		_TessMaxDisp("Max Displacement", Float) = 20
		_TessPhongStrength("Phong Tess Strength", Range(0, 1)) = 0.5
		_TessHeightTex("Height Map", 2D) = "gray" {}
		_TessDisplacement("Displacement", Range(0, 1.0)) = 0.3

		[Space(4)]
		[Header(Refraction Settings ___________________________________________________)]
		[Space(4)]
		_RefractionTex("Refraction Tex" , 2D) = "black" {}

		[Space(4)]
		[Header(SurfaceOutput Settings ___________________________________________________)]
		[Space(4)]
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
	}
		SubShader{
			LOD 200
			Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#include "UnityCG.cginc"
			#include "Tessellation.cginc"
			// Physically based Standard lighting model, and enable shadows on all light types
			#pragma surface surf Standard fullforwardshadows vertex:vert alpha:fade tessellate:tessFunction tessphong:_TessPhongStrength

			// Use shader model 3.0 target, to get nicer looking lighting
			#pragma target 4.6

			sampler2D _CameraDepthTexture;

			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize;
			sampler2D _WaterNormal;

			float _WaterAngle;
			float _WaterSpeed;

			float _WaterDepth;
			float4 _ShallowColor;
			float4 _DeepColor;
			float _RefractDistortion;

			float _EdgeLength;
			float _TessMaxDisp;
			float _TessPhongStrength;
			sampler2D _TessHeightTex;
			float _TessDisplacement;

			struct Input {
				half2 uv_texcoord;
				float2 uv_TessNormalMap;
				float2 uv_WaterNormal;
				float3 worldNormal;
				float3 worldPos;
				INTERNAL_DATA
				float4 vertexColor : COLOR;
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

			float4 tessFunction(appdata_full v0, appdata_full v1, appdata_full v2)
			{
				return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _EdgeLength, _TessMaxDisp);
			}

			float2 RotationVector(float2 vec, float angle)
			{
				float radZ = radians(-angle);
				float sinZ, cosZ;
				sincos(radZ, sinZ, cosZ);
				return float2(vec.x * cosZ - vec.y * sinZ,
					vec.x * sinZ + vec.y * cosZ);
			}

			void vert(inout appdata_full v)
			{
				float d = tex2Dlod(_TessHeightTex, float4(v.texcoord.xy, 0, 0)).r * _TessDisplacement;
				v.vertex.xyz += v.normal * d;
			}

			void surf(Input IN, inout SurfaceOutputStandard o) {
				float linearEyeDepth = 1;
				//linearEyeDepth 像素深度
				{
					linearEyeDepth = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, IN.screenPos))) - IN.screenPos.w;
				}

				//_WaterDirection
				fixed2 offsetDirection = RotationVector(float2(0, 1), _WaterAngle);
				fixed3 bump = UnpackNormal(tex2D(_WaterNormal, IN.uv_WaterNormal + offsetDirection * _Time.yy * _WaterSpeed));
				
				//对屏幕图像的采样坐标进行偏移
				//选择使用切线空间下的法线方向来进行偏移是因为该空间下的法线可以反映顶点局部空间下的法线方向
				fixed2 offset = bump * _RefractDistortion * _RefractionTex_TexelSize;

				//对scrPos偏移后再透视除法得到真正的屏幕坐标
				float4 uv = IN.screenPos + float4(offset, 0, 0) * saturate(linearEyeDepth);
				half4 refractionColor = tex2Dproj(_RefractionTex,UNITY_PROJ_COORD(uv));
				
				//水深度颜色
				half d = saturate(_WaterDepth * linearEyeDepth);
				d = 1.0 - d;
				d = lerp(d, pow(d, 3), 0.5);
				half4 waterColor = lerp(_DeepColor, _ShallowColor, d);
				waterColor *= refractionColor;

				//o.Albedo = IN.vertexColor * linearEyeDepth; Emission
				o.Albedo = waterColor;
				//o.Emission = waterColor;
				o.Alpha = 1;

				//o.Normal = UnpackNormal(tex2D(_TessNormalMap, IN.uv_TessNormalMap));
				// Metallic and smoothness come from slider variables
				o.Metallic = _Metallic;
				o.Smoothness = _Glossiness;				
			}
			ENDCG
		}
		FallBack "Diffuse"
}