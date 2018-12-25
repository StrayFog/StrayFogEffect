Shader "StrayFog/Nature/Water" {
	Properties {
		[Enum(Off,0,On,1)]_ZWrite("ZWrite", Float) = 1.0
		[Enum(UnityEngine.Rendering.CullMode)] _Culling("Culling", Float) = 0

		[Space(4)]
		[Header(_______________ Wave Setting ___________________)]
		[Space(4)]
		[KeywordEnum(Off,Gerstner)]
		_WaveFeature("Wave", Float) = 0

		[Space(5)]
		[LuxWaterVectorThreeDrawer]
		_GerstnerVertexIntensity("    Final Displacement", Vector) = (1.0,1.0,1.0,0.0)
	}
	SubShader {
		Tags {"Queue" = "Transparent-1" "RenderType" = "Opaque" "ForceNoShadowCasting" = "True"}
		LOD 200

		ZWrite[_ZWrite]
		ZTest LEqual
		Cull[_Culling]
		Blend SrcAlpha OneMinusSrcAlpha

		GrabPass{ "_GrabTexture" }

		CGPROGRAM
		#include "UnityCG.cginc"
		#include "StrayFogWater.cginc"
		#include "StrayFogWater_Helper.cginc"
		#include "StrayFogWater_GerstnerWave.cginc"		

		#pragma target 5.0
		#pragma surface StrayFogSurf StandardSpecular vertex:StrayFogVert keepalpha		
		
		#pragma shader_feature _ _WAVEFEATURE_GERSTNER
		ENDCG
	}
	FallBack "Diffuse"
}
