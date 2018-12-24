Shader "StrayFog/Nature/Water" {
	Properties {
		[Enum(Off,0,On,1)]_ZWrite("ZWrite", Float) = 1.0
		[Enum(UnityEngine.Rendering.CullMode)] _Culling("Culling", Float) = 0

		

		[Space(4)]
		[Header(Water Settings ___________________________________________________)]
		[Space(4)]
		_NormalTex2D("Water Normal", 2D) = "bump" {}
		_NormalScale("Water NormalScale",float) = 1
		_WaterAngle("Water Angle",Range(0,360)) = 0
		_WaterOverlap("Water Overlap",Range(0,90)) = 5
		_WaterSpeed("Water Speed",float) = 0.1
		_WaterRefraction("Water Refraction",Range(0,1)) = 66
		_ShalowColor("Shalow Color", Color) = (0.23,0.34,0.2,1)
		_DeepColor("Deep Color", Color) = (0,0.32,0.5,0)

		[Header(_____________________ Foam ______________________________)]
		_FoamTex2D("Water Foam", 2D) = "white" {}

		[Header(_____________________ Noise ______________________________)]
		_NoiseTex2D("Water Noise", 2D) = "white" {}

		[KeywordEnum(Off,Wave,Gerstner)]
		_WaveMode("WaveMode", Float) = 0
		_NormalSmoothing("Normal Smoothing",range(0,1)) = 1

		[Header(_____________________ Wave ______________________________)]
		_Amplitude("Amplitude", float) = 0.05
		_Frequency("Frequency",float) = 1
		_Speed("Wave Speed", float) = 1

		[Header(_____________________ Gerstner _____________________________)]
		_Steepness("Wave Steepness",float) = 1
		_WSpeed("Wave Speed", Vector) = (1.2, 1.375, 1.1, 1.5)
		_WDirectionAB("Wave1 Direction", Vector) = (0.3 ,0.85, 0.85, 0.25)
		_WDirectionCD("Wave2 Direction", Vector) = (0.1 ,0.9, 0.5, 0.5)

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
		#pragma surface tessSurf StandardSpecular keepalpha fullforwardshadows vertex:StrayFogVert tessellate:StrayFogTessFunction tessphong:_TessPhongStrength

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		#pragma shader_feature _ _WAVEMODE_WAVE _ _WAVEMODE_GERSTNER
		ENDCG
	}
	FallBack "Diffuse"
}
