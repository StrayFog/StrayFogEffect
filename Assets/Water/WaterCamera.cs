using UnityEngine;
[AddComponentMenu("Effect/Water/WaterCamera")]
[ExecuteInEditMode]
public class WaterCamera : MonoBehaviour
{
    /// <summary>
    /// 摄像机绘制的图片
    /// </summary>
    public RenderTexture renderTexture { get; private set; }
    /// <summary>
    /// 摄像机
    /// </summary>
    Camera mCamera = null;
    /// <summary>
    /// 绘制水纹纹理
    /// </summary>
    /// <param name="_eyeCamera">眼睛摄像机</param>
    /// <param name="_waterPlaneLayer">水平面Layer</param>
    /// <param name="_waterPlanePosition">水平面位置</param>
    /// <param name="_waterPlaneNormal">水平面法线</param>
    /// <param name="_waterPlaneSideSign">水平面边(1:水平面上,-1:水平面下)</param>
    /// <param name="_clipPlaneOffset">裁剪面偏移</param>
    public void Render(Camera _eyeCamera,int _waterPlaneLayer, Vector3 _waterPlanePosition,Vector3 _waterPlaneNormal, int _waterPlaneSideSign,float _clipPlaneOffset)
    {
        #region 创建绘制水纹的摄像机
        if (mCamera == null)
        {
            mCamera = GetComponent<Camera>();
            if (mCamera == null)
            {
                mCamera = gameObject.AddComponent<Camera>();
            }
            mCamera.enabled = false;             
        }
        #endregion

        #region 设置摄像机属性
        mCamera.CopyFrom(_eyeCamera);
        mCamera.transform.position = _eyeCamera.transform.position;
        mCamera.transform.rotation = _eyeCamera.transform.rotation;
        mCamera.clearFlags = _eyeCamera.clearFlags;
        mCamera.backgroundColor = _eyeCamera.backgroundColor;
        if (mCamera.clearFlags == CameraClearFlags.Skybox)
        {
            Skybox sky = _eyeCamera.GetComponent(typeof(Skybox)) as Skybox;
            Skybox mysky = mCamera.GetComponent(typeof(Skybox)) as Skybox;
            if (mysky)
            {
                if (!sky || !sky.material)
                {
                    mysky.enabled = false;
                }
                else
                {
                    mysky.enabled = true;
                    mysky.material = sky.material;
                }
            }            
        }
        mCamera.farClipPlane = _eyeCamera.farClipPlane;
        mCamera.nearClipPlane = _eyeCamera.nearClipPlane;
        mCamera.orthographic = _eyeCamera.orthographic;
        mCamera.fieldOfView = _eyeCamera.fieldOfView;
        mCamera.aspect = _eyeCamera.aspect;
        mCamera.orthographicSize = _eyeCamera.orthographicSize;
        mCamera.worldToCameraMatrix = _eyeCamera.worldToCameraMatrix;
        mCamera.cullingMask = ~(1 << _waterPlaneLayer); // never render water layer        
        mCamera.targetTexture = null;
        Vector4 clipPlane = CameraSpacePlane(mCamera, _waterPlanePosition, _waterPlaneNormal, _waterPlaneSideSign, _clipPlaneOffset);
        Matrix4x4 projection = _eyeCamera.projectionMatrix;
        CalculateObliqueMatrix(ref projection, clipPlane);
        mCamera.projectionMatrix = projection;
        #endregion

        mCamera.Render();
    }


    ///// <summary>
    ///// 水摄像机
    ///// </summary>
    //public Camera waterCamera { get; private set; }


    //public bool m_DisablePixelLights = true;
    //public int m_TextureSize = 256;
    //public float m_ClipPlaneOffset = 0.07f;
    //public LayerMask m_RefractLayers = -1;
    //Camera m_RefractionCamera;
    //private RenderTexture m_RefractionTexture = null;
    //private int m_OldRefractionTextureSize = 0;
    //private bool s_InsideWater = false;
    //// This is called when it's known that the object will be rendered by some
    //// camera. We render reflections / refractions and do other updates here.
    //// Because the script executes in edit mode, reflections for the scene view
    //// camera will just work!
    //public void OnWillRenderObject()
    //{
    //    if (!enabled || !GetComponent<Renderer>() || !GetComponent<Renderer>().sharedMaterial || !GetComponent<Renderer>().enabled)
    //        return;

    //    Camera cam = Camera.current;
    //    if (!cam)
    //        return;

    //    // Safeguard from recursive water reflections.		
    //    if (s_InsideWater)
    //        return;
    //    s_InsideWater = true;
    //    this.gameObject.layer = 4;
    //    // Actual water rendering mode depends on both the current setting AND
    //    // the hardware support. There's no point in rendering refraction textures
    //    // if they won't be visible in the end.

    //    CreateWaterObjects(cam, ref m_RefractionCamera);

    //    // find out the reflection plane: position and normal in world space
    //    Vector3 pos = transform.position;
    //    Vector3 normal = transform.up;

    //    // Optionally disable pixel lights for reflection/refraction
    //    int oldPixelLightCount = QualitySettings.pixelLightCount;
    //    if (m_DisablePixelLights)
    //        QualitySettings.pixelLightCount = 0;

    //    UpdateCameraModes(cam, m_RefractionCamera);
    //    m_RefractionCamera.worldToCameraMatrix = cam.worldToCameraMatrix;

    //    // Setup oblique projection matrix so that near plane is our reflection
    //    // plane. This way we clip everything below/above it for free.
    //    Vector4 clipPlane = CameraSpacePlane(m_RefractionCamera, pos, normal, -1.0f);
    //    Matrix4x4 projection = cam.projectionMatrix;
    //    CalculateObliqueMatrix(ref projection, clipPlane);
    //    m_RefractionCamera.projectionMatrix = projection;

    //    m_RefractionCamera.cullingMask = ~(1 << 4) & m_RefractLayers.value; // never render water layer
    //    //refractionCamera.targetTexture = m_RefractionTexture;
    //    m_RefractionCamera.transform.position = cam.transform.position;
    //    m_RefractionCamera.transform.rotation = cam.transform.rotation;
    //    m_RefractionCamera.Render();
    //    WaterCamera rcm = m_RefractionCamera.gameObject.GetComponent<WaterCamera>();
    //    if (rcm)
    //    {
    //        GetComponent<Renderer>().sharedMaterial.SetTexture("_RefractionTex", rcm.waterRenderTexture);
    //        //GetComponent<Renderer>().sharedMaterial.SetTexture("_RefractionTex", m_RefractionTexture);
    //    }


    //    // Restore pixel light count
    //    if (m_DisablePixelLights)
    //        QualitySettings.pixelLightCount = oldPixelLightCount;
    //    s_InsideWater = false;
    //}


    //// Cleanup all the objects we possibly have created
    //void OnDisable()
    //{
    //    if (m_RefractionTexture)
    //    {
    //        DestroyImmediate(m_RefractionTexture);
    //        m_RefractionTexture = null;
    //    }
    //    if (m_RefractionCamera)
    //    {
    //        DestroyImmediate(m_RefractionCamera.gameObject);
    //        m_RefractionCamera = null;
    //    }
    //}

    //private void UpdateCameraModes(Camera src, Camera dest)
    //{
    //    if (dest == null)
    //        return;
    //    // set water camera to clear the same way as current camera
    //    dest.clearFlags = src.clearFlags;
    //    dest.backgroundColor = src.backgroundColor;
    //    if (src.clearFlags == CameraClearFlags.Skybox)
    //    {
    //        Skybox sky = src.GetComponent(typeof(Skybox)) as Skybox;
    //        Skybox mysky = dest.GetComponent(typeof(Skybox)) as Skybox;
    //        if (!sky || !sky.material)
    //        {
    //            mysky.enabled = false;
    //        }
    //        else
    //        {
    //            mysky.enabled = true;
    //            mysky.material = sky.material;
    //        }
    //    }
    //    // update other values to match current camera.
    //    // even if we are supplying custom camera&projection matrices,
    //    // some of values are used elsewhere (e.g. skybox uses far plane)
    //    dest.farClipPlane = src.farClipPlane;
    //    dest.nearClipPlane = src.nearClipPlane;
    //    dest.orthographic = src.orthographic;
    //    dest.fieldOfView = src.fieldOfView;
    //    dest.aspect = src.aspect;
    //    dest.orthographicSize = src.orthographicSize;
    //}

    //// On-demand create any objects we need for water
    //private void CreateWaterObjects(Camera currentCamera, ref Camera refractionCamera)
    //{
    //    if (!refractionCamera) // catch both not-in-dictionary and in-dictionary-but-deleted-GO
    //    {
    //        GameObject go = new GameObject("Water Refr Camera id" + GetInstanceID() + " for " + currentCamera.GetInstanceID(), typeof(Camera), typeof(Skybox));
    //        refractionCamera = go.GetComponent<Camera>();
    //        refractionCamera.enabled = false;
    //        refractionCamera.transform.position = transform.position;
    //        refractionCamera.transform.rotation = transform.rotation;
    //        refractionCamera.gameObject.AddComponent<FlareLayer>();
    //        refractionCamera.targetDisplay = 7;
    //        refractionCamera.gameObject.AddComponent<WaterCamera>();
    //        //go.hideFlags = HideFlags.DontSave;
    //    }
    //}

    // Extended sign: returns -1, 0 or 1 based on sign of a
    private static float sgn(float a)
    {
        if (a > 0.0f) return 1.0f;
        if (a < 0.0f) return -1.0f;
        return 0.0f;
    }

    // Given position/normal of the plane, calculates plane in camera space.
    private Vector4 CameraSpacePlane(Camera cam, Vector3 pos, Vector3 normal, float sideSign, float _clipPlaneOffset)
    {
        Vector3 offsetPos = pos + normal * _clipPlaneOffset;
        Matrix4x4 m = cam.worldToCameraMatrix;
        Vector3 cpos = m.MultiplyPoint(offsetPos);
        Vector3 cnormal = m.MultiplyVector(normal).normalized * sideSign;
        return new Vector4(cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot(cpos, cnormal));
    }

    // Adjusts the given projection matrix so that near plane is the given clipPlane
    // clipPlane is given in camera space. See article in Game Programming Gems 5 and
    // http://aras-p.info/texts/obliqueortho.html
    private static void CalculateObliqueMatrix(ref Matrix4x4 projection, Vector4 clipPlane)
    {
        Vector4 q = projection.inverse * new Vector4(
            sgn(clipPlane.x),
            sgn(clipPlane.y),
            1.0f,
            1.0f
        );
        Vector4 c = clipPlane * (2.0F / (Vector4.Dot(clipPlane, q)));
        // third row = clip plane - fourth row
        projection[2] = c.x - projection[3];
        projection[6] = c.y - projection[7];
        projection[10] = c.z - projection[11];
        projection[14] = c.w - projection[15];
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        renderTexture = source;
    }
}
