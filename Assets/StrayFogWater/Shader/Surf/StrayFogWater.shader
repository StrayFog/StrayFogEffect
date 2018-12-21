Shader "StrayFog/Nature/Water" {
	Properties {
		[Enum(Off,0,On,1)]_ZWrite("ZWrite", Float) = 1.0
		[Enum(UnityEngine.Rendering.CullMode)] _Culling("Culling", Float) = 0

		[KeywordEnum(Off,Wave,Gerstner)]
		_WaveMode("WaveMode", Float) = 0

		[Space(4)]
		[Header(Water Settings ___________________________________________________)]
		[Space(4)]
		_WaterNormal("Water Normal", 2D) = "bump" {}
		_WaterNormalScale("Water NormalScale",float) = 1

		[Space(4)]
		[Header(Light Settings ___________________________________________________)]
		[Space(4)]
		_Specular("Specular",Color) = (1,1,1,1)
		_Smoothness("Smoothness", Range(0,1)) = 0.5
		_Occlusion("Occlusion", Range(0,1)) = 1

		[Space(4)]
		[Header(Tessellate Mesh ___________________________________________________)]
		[Space(4)]
		_TesselationTex("Tesselation", 2D) = "black" {}
		_TessEdgeLength("Edge length", Range(2, 50)) = 25
		_TessMaxDisp("Max Displacement", Float) = 20
		_TessPhongStrength("Phong Tess Strength", Range(0, 1)) = 0.5
		_TessDisplacement("Displacement", Range(0, 1)) = 0.3
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		#include "UnityCG.cginc"
		#include "Tessellation.cginc"
		#include "StrayFogWater.cginc"
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface tessSurf StandardSpecular keepalpha fullforwardshadows vertex:tessVert tessellate:tessFunction tessphong:_TessPhongStrength

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		#pragma shader_feature _ _WAVEMODE_WAVE _ _WAVEMODE_GERSTNER
		ENDCG
	}
	FallBack "Diffuse"
}
