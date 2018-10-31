using UnityEngine;
/// <summary>
/// 折射效果
/// </summary>
[AddComponentMenu("Effect/Water/WaterStatic")]
[ExecuteInEditMode]// Make water live-update even when not in play mode
public class WaterStatic : MonoBehaviour
{
    /// <summary>
    /// 是否使用反射
    /// </summary>
    public bool useReflective = true;
    /// <summary>
    /// 是否使用折射
    /// </summary>
    public bool useRefractive = true;    
    /// <summary>
    /// 裁剪面偏移
    /// </summary>
    public float clipPlaneOffset = 0.07f;
    /// <summary>
    /// 眼睛摄像机
    /// </summary>
    public Camera eyeCamera;

    /// <summary>
    /// 反射摄像机
    /// </summary>
    WaterCamera mReflectiveCamera;
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
        this.gameObject.layer = 4;
        if (mWaterMaterial == null)
        {
            mWaterMaterial = GetComponent<Renderer>().sharedMaterial;
        }

        if (useReflective && useRefractive)
        {
            mWaterMaterial.SetInt("_WaterDisplayMode", 0);
        }
        else if (useReflective)
        {
            mWaterMaterial.SetInt("_WaterDisplayMode", 1);
        }
        else if (useRefractive)
        {
            mWaterMaterial.SetInt("_WaterDisplayMode", 2);
        }
        else
        {
            mWaterMaterial.SetInt("_WaterDisplayMode", -1);
        }

        eyeCamera.depthTextureMode |= DepthTextureMode.Depth;
        #endregion

        #region 是否绘制反射
        if (useReflective)
        {
            if (mReflectiveCamera == null)
            {
                Transform rc = transform.Find("ReflectiveCamera");
                if (rc)
                {
                    mReflectiveCamera = rc.GetComponent<WaterCamera>();
                }
                else
                {
                    GameObject go = new GameObject("ReflectiveCamera");
                    go.transform.SetParent(transform, false);
                    mReflectiveCamera = go.AddComponent<WaterCamera>();
                }                
            }
            mReflectiveCamera.Render(eyeCamera, this.gameObject.layer, transform.position, transform.up, 1, clipPlaneOffset);
            if (mReflectiveCamera.renderTexture)
            {
                mWaterMaterial.SetTexture("_ReflectionTex", mReflectiveCamera.renderTexture);
            }            
        }
        else if(mReflectiveCamera)
        {
            DestroyImmediate(mReflectiveCamera.gameObject);
            mReflectiveCamera = null;
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
            mRefractiveCamera.Render(eyeCamera, this.gameObject.layer,transform.position, transform.up, -1, clipPlaneOffset);
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
