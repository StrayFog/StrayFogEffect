Shader "Effect/Water/Water (Static)"
{
	Properties{
		_WaterNormal("Water Normal Map", 2D) = "bump" {}
		_WaterNormalScale("Water Normal Scale", Range(0,1)) = 0.6
		_WaterAngle("Water Angle",Range(0,360)) = 0
		_WaterSpeed("Water Speed",Range(0.01,1)) = 0.03
		_WaterDepth("Water Depth", Range(0 , 1)) = 0.01
		_ShallowColor("Shallow Color", Color) = (0.52,0.66,0.61,1)
		_DeepColor("Deep Color", Color) = (0.05,0.09,0.235,1)
		_WaterRefract("Water Refract", Range(0, 1000)) = 100  //控制模拟折射时图像的扭曲程度
		_WaterFoam("Water Foam Map", 2D) = "black" {}

		[Space(4)]
		[Header(SurfaceOutput Settings ___________________________________________________)]
		[Space(4)]		
		_SpecColor("SpecColor", color) = (1, 1, 1, 1)
		_Specular("Specular", float) = 1.86
		_Gloss("Gloss", float) = 0.71

		[Space(4)]
		[Header(Tessellate Settings ___________________________________________________)]
		[Space(4)]
		_EdgeLength("Edge length", Range(2, 50)) = 25
		_TessMaxDisp("Max Displacement", Float) = 20
		_TessPhongStrength("Phong Tess Strength", Range(0, 1)) = 0.5
		_WaterTesselation("Water Tesselation", 2D) = "black" {}
		_TessDisplacement("Displacement", Range(0, 1.0)) = 0.1			
	}
	SubShader{
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
		Blend SrcAlpha OneMinusSrcAlpha
		GrabPass { "_GrabTex" }

		CGPROGRAM
		#include "UnityCG.cginc"
		#include "Tessellation.cginc"
		#include "StrayFogRiverWave.cginc"
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf WaterLight fullforwardshadows vertex:tessVert alpha:fade tessellate:tessFunction tessphong:_TessPhongStrength		
		ENDCG
	}
	FallBack "Diffuse"
}