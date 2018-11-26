//获得CameraDepthTexture的LinearEyeDepth
float StrayFogLinearEyeDepth(sampler2D _CameraDepthTexture,float4 _screenPos)
{
	return LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, _screenPos))) - _screenPos.w;
}