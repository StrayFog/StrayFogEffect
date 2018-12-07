Shader "Effect/Water/Water (Static)"
{
	Properties{
		[Enum(Off,0,On,1)]_ZWrite("ZWrite", Float) = 1.0
		[Enum(UnityEngine.Rendering.CullMode)] _Culling("Culling", Float) = 0

		[Space(4)]
		[Header(Water Settings ___________________________________________________)]
		[Space(4)]
		_WaterNormal("Water Normal", 2D) = "bump" {}
		_WaterNormalScale("Water NormalScale",float) = 1		
		_WaterAngle("Water Angle",Range(0,360)) = 0
		_WaterOverlap("Water Overlap",Range(0,90)) = 5
		_WaterSpeed("Water Speed",float) = 0.1
		_WaterRefraction("Water Refraction",Range(0,512)) = 66

		[Space(4)]
		[Header(Water Foam Settings ___________________________________________________)]
		[Space(4)]
		_WaterFoam("Water Foam", 2D) = "white" {}
		_WaterNoise("Water Noise", 2D) = "white" {}

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
		Tags{ "Queue" = "Transparent-1" "RenderType" = "Opaque" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		ZWrite [_ZWrite]
		ZTest LEqual
		Cull [_Culling]
		Blend SrcAlpha OneMinusSrcAlpha
		
		GrabPass { "_GrabTex" }

		CGPROGRAM
		#include "UnityCG.cginc"
		#include "Tessellation.cginc"
		#include "StrayFogWaterSurf.cginc"
		// Physically based Standard lighting model, and enable shadows on all light types
		//StandardSpecular
		#pragma surface tessSurf StandardSpecular keepalpha vertex:tessVert tessellate:tessFunction tessphong:_TessPhongStrength		
		ENDCG
	}
	FallBack "Diffuse"
}