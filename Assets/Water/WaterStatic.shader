Shader "Effect/Water/Water (Static)"
{
	Properties{
		_WaterNormal("Water Normal", 2D) = "bump" {}

		[Space(4)]
		[Header(Tessellate Wave ___________________________________________________)]
		[Space(4)]
		_UVVDirection1UDirection0("UV - V Direction (1) U Direction (0)", Int) = 0
		_WaterMixSpeed("Water Mix Speed", Vector) = (0.01,0.05,0,0)
		_WaterMainSpeed("Water Main Speed", Vector) = (1,1,0,0)
		_WaterTessScale("Water Tess Scale", Float) = 0.06

		[Space(4)]
		[Header(SurfaceOutput Settings ___________________________________________________)]
		[Space(4)]		
		_SpecColor("SpecColor", color) = (1, 1, 1, 1)
		_Specular("Specular", float) = 1.86
		_Gloss("Gloss", float) = 0.71

		[Space(4)]
		[Header(Tessellate Mesh ___________________________________________________)]
		[Space(4)]
		_TessEdgeLength("Edge length", Range(2, 50)) = 25
		_TessMaxDisp("Max Displacement", Float) = 20
		_TessPhongStrength("Phong Tess Strength", Range(0, 1)) = 0.5
		_TesselationTex("Tesselation", 2D) = "black" {}	
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
		#pragma surface surf StandardSpecular fullforwardshadows vertex:tessVert alpha:fade tessellate:tessFunction tessphong:_TessPhongStrength		
		ENDCG
	}
	FallBack "Diffuse"
}