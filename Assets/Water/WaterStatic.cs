using UnityEngine;
/// <summary>
/// 折射效果
/// </summary>
[AddComponentMenu("Effect/Water/WaterStatic")]
[ExecuteInEditMode]// Make water live-update even when not in play mode
public class WaterStatic : MonoBehaviour
{
    /// <summary>
    /// 是否绘制折射
    /// </summary>
    public bool useRefractive;
    /// <summary>
    /// 眼睛摄像机
    /// </summary>
    public Camera eyeCamera;
    /// <summary>
    /// 折射摄像机
    /// </summary>
    WaterCamera mRefractiveCamera;
    /// <summary>
    /// 水材质
    /// </summary>
    Material mWaterMaterial;
    /// <summary>
    /// 是否在绘制水
    /// </summary>
    bool mIsRenderWater = false;
    #region OnWillRenderObject
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
        mIsRenderWater = true;
        #endregion

        #region 固定设置
        gameObject.layer = 4;        
        eyeCamera.depthTextureMode |= DepthTextureMode.Depth;
        if (mWaterMaterial == null)
        {
            mWaterMaterial = GetComponent<Renderer>().sharedMaterial;
        }
        #endregion

        #region 是否绘制折射
        if (useRefractive)
        {
            if (mRefractiveCamera == null)
            {
                Transform rc = transform.Find("RefractiveCamera");
                if (rc)
                {
                    mRefractiveCamera = rc.GetComponent<WaterCamera>();
                }
                else
                {
                    GameObject go = new GameObject("RefractiveCamera");
                    go.transform.SetParent(transform, false);
                    mRefractiveCamera = go.AddComponent<WaterCamera>();
                }                
            }
            mRefractiveCamera.RenderGrabPass(eyeCamera, gameObject.layer);
            if (mRefractiveCamera.renderTexture)
            {
                mWaterMaterial.SetTexture("_RefractionTex", mRefractiveCamera.renderTexture);
            }            
        }
        else if (mRefractiveCamera)
        {       
            DestroyImmediate(mRefractiveCamera.gameObject);
            mRefractiveCamera = null;
        }
        #endregion

        mIsRenderWater = false;
    }
    #endregion
}
