using UnityEngine;
[AddComponentMenu("StrayFog/Water")]
[ExecuteInEditMode]
public class StrayFogWater : MonoBehaviour {
    /// <summary>
    /// 眼睛摄像机
    /// </summary>
    Camera eyeCamera;
    /// <summary>
    /// 是否绘制水
    /// </summary>
    bool mIsRenderWater;
    /// <summary>
    /// OnWillRenderObject
    /// </summary>
    void OnWillRenderObject()
    {
        #region 是否可绘制
        if (!enabled || !GetComponent<Renderer>() || !GetComponent<Renderer>().sharedMaterial || !GetComponent<Renderer>().enabled)
            return;
        eyeCamera = Camera.current;
        if (!eyeCamera)
            return;
        if (mIsRenderWater)
            return;
        #endregion

        mIsRenderWater = true;
        #region 固定设置
        gameObject.layer = 4;
        eyeCamera.depthTextureMode |= DepthTextureMode.Depth;
        #endregion
        mIsRenderWater = false;
    }
}
