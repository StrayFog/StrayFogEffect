Shader "Effect/Water/Water (Static)"
{
	Properties{
		_WaterNormal("Water Normal", 2D) = "bump" {}
		_WaterNormalScale("Water Scale", Range(0,1)) = 0.5
		_WaterRefraction("Water Refraction", Range(0,2)) = 1.33
		_WaterFoam("Water Foam", 2D) = "grap" {}
		_WaterShallowColor("Shallow Color", Color) = (1,1,1,1)
		_WaterDeepColor("Deep Color", Color) = (0,0,0,0)
		_WaterDepth("Water Depth", Range(0,1)) = 0.05

		[Space(4)]
		[Header(Tessellate Wave ___________________________________________________)]
		[Space(4)]
		_WaterAngle("Water Angle", Range(0,360)) = 0
		_WaterWaveOverlay("Water Overlay", Range(0,90)) = 10
		_WaterSpeed("Water Speed", Range(0,1)) = 0.05
		_WaterTessScale("Water Tess Scale", Range(0,0.2)) = 0.02

		[Space(4)]
		[Header(SurfaceOutput Settings ___________________________________________________)]
		[Space(4)]
		_Specular("Specular",Color) = (1,1,1,1)
		_Smoothness("Smoothness", Range(0,1)) = 0.5
		_Occlusion("Occlusion", Range(0,1)) = 1
		
		[Space(4)]
		[Header(Tessellate Mesh ___________________________________________________)]
		[Space(4)]
		_TessEdgeLength("Edge length", Range(2, 50)) = 25
		_TessMaxDisp("Max Displacement", Float) = 20
		_TessPhongStrength("Phong Tess Strength", Range(0, 1)) = 0.5
		_TesselationTex("Tesselation", 2D) = "black" {}	

		[HideInInspector] _texcoord("", 2D) = "white" {}
		[HideInInspector] __dirty("", Int) = 1
	}
	SubShader{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Geometry+999" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		GrabPass { "_GrabTex" }

		CGPROGRAM
		#include "UnityCG.cginc"
		#include "Tessellation.cginc"
		#include "StrayFogRiverWave.cginc"
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface tessSurf StandardSpecular keepalpha vertex:tessVert tessellate:tessFunction tessphong:_TessPhongStrength		
		ENDCG
	}
	FallBack "Diffuse"
}