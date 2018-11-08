Shader "Effect/Water/Water (Tessellate)"
{
	Properties{
		_EdgeLength("Edge length", Range(2, 50)) = 25
		_TessMaxDisp("Max Displacement", Float) = 20
		_TessPhongStrength("Phong Tess Strength", Range(0, 1)) = 0.5
		_TessHeightTex("Height Map", 2D) = "gray" {}
		_TessDisplacement("Displacement", Range(0, 1.0)) = 0.3
	}
		SubShader{
			CGPROGRAM
			#include "UnityCG.cginc"
			#include "Tessellation.cginc"
			// Physically based Standard lighting model, and enable shadows on all light types
			#pragma surface surf Lambert vertex:vert tessellate:tessFunction tessphong:_TessPhongStrength

			// Use shader model 3.0 target, to get nicer looking lighting
			#pragma target 4.6
			float _EdgeLength;
			float _TessMaxDisp;
			float _TessPhongStrength;
			sampler2D _TessHeightTex;
			float _TessDisplacement;

			struct Input {
				float2 uv_TessHeightTex;
				INTERNAL_DATA
			};

			// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
			// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
			// #pragma instancing_options assumeuniformscaling
			UNITY_INSTANCING_BUFFER_START(Props)
				// put more per-instance properties here
			UNITY_INSTANCING_BUFFER_END(Props)

			float4 tessFunction(appdata_base v0, appdata_base v1, appdata_base v2)
			{
				return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _EdgeLength, _TessMaxDisp);
			}		

			void vert(inout appdata_base v)
			{
				float d = tex2Dlod(_TessHeightTex, float4(v.texcoord.xy, 0, 0)).r * _TessDisplacement;
				v.vertex.xyz += v.normal * d;
			}

			void surf(Input IN, inout SurfaceOutput o) {	

			}
			ENDCG
		}
		FallBack "Diffuse"
}