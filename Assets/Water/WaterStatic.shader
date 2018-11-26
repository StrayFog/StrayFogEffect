Shader "Effect/Water/Water (Static)"
{
	Properties{
		_GAmplitude("Wave Amplitude", Vector) = (0.3 ,0.35, 0.25, 0.25)
		_GFrequency("Wave Frequency", Vector) = (1.3, 1.35, 1.25, 1.25)
		_GSteepness("Wave Steepness", Vector) = (1.0, 1.0, 1.0, 1.0)
		_GSpeed("Wave Speed", Vector) = (1.2, 1.375, 1.1, 1.5)
		_GDirectionAB("Wave Direction", Vector) = (0.3 ,0.85, 0.85, 0.25)
		_GDirectionCD("Wave Direction", Vector) = (0.1 ,0.9, 0.5, 0.5)

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
		#include "StrayFogWaterSurf.cginc"
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface tessSurf StandardSpecular keepalpha vertex:tessVert tessellate:tessFunction tessphong:_TessPhongStrength		
		ENDCG
	}
	FallBack "Diffuse"
}