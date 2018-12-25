Shader "StrayFog/Nature/Water" {
	Properties {
		[Enum(Off,0,On,1)]_ZWrite("ZWrite", Float) = 1.0
		[Enum(UnityEngine.Rendering.CullMode)] _Culling("Culling", Float) = 0

		

		[Space(4)]
		[Header(_______________ Wave Setting ___________________)]
		[Space(4)]
		[KeywordEnum(Off,Gerstner)]
		_WaveFeature("Wave", Float) = 0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		#include "UnityCG.cginc"
		#include "StrayFogWater.cginc"

		#pragma target 5.0
		#pragma surface StrayFogSurf StandardSpecular vertex:StrayFogVert keepalpha		
		
		#pragma shader_feature _ _WAVEFEATURE_GERSTNER
		ENDCG
	}
	FallBack "Diffuse"
}
