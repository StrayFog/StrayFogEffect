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

        #region 创建绘制水纹RenderTexture
        if (!renderTexture)
        {            
            renderTexture = new RenderTexture(512,512, 16);
            renderTexture.name = "WaterRenderTexture_" + _waterPlaneSideSign.ToString();
            renderTexture.isPowerOfTwo = true;
            renderTexture.hideFlags = HideFlags.DontSave;
        }
        #endregion

        #region 设置摄像机属性
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
        mCamera.targetTexture = renderTexture;
        mCamera.depthTextureMode = DepthTextureMode.None;
        mCamera.renderingPath = RenderingPath.Forward;
        Vector3 reflectionOldpos = Vector3.zero;
        Vector3 reflectionNewpos = Vector3.zero;

        if (_waterPlaneSideSign > 0)
        {
            float d = -Vector3.Dot(_waterPlaneNormal, _waterPlanePosition) - _clipPlaneOffset;
            Vector4 reflectionPlane = new Vector4(_waterPlaneNormal.x, _waterPlaneNormal.y, _waterPlaneNormal.z, d);

            Matrix4x4 reflection = Matrix4x4.zero;
            CalculateReflectionMatrix(ref reflection, reflectionPlane);
            reflectionOldpos = _eyeCamera.transform.position;
            reflectionNewpos = reflection.MultiplyPoint(reflectionOldpos);
            mCamera.worldToCameraMatrix = mCamera.worldToCameraMatrix * reflection;
        }
        Vector4 clipPlane = CameraSpacePlane(mCamera, _waterPlanePosition, _waterPlaneNormal, _waterPlaneSideSign, _clipPlaneOffset);
        Matrix4x4 projection = _eyeCamera.projectionMatrix;
        CalculateObliqueMatrix(ref projection, clipPlane);
        mCamera.projectionMatrix = projection;
        #endregion

        #region 绘图
        if (_waterPlaneSideSign > 0)
        {
            GL.invertCulling = true;
            mCamera.transform.position = reflectionNewpos;
            Vector3 euler = _eyeCamera.transform.eulerAngles;
            mCamera.transform.eulerAngles = new Vector3(-euler.x, euler.y, euler.z);
            mCamera.Render();
            mCamera.transform.position = reflectionOldpos;
            GL.invertCulling = false;
        }
        else
        {
            mCamera.Render();
        }
        #endregion
    }

    #region 视图矩阵
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

    void CalculateReflectionMatrix(ref Matrix4x4 reflectionMat, Vector4 plane)
    {
        reflectionMat.m00 = (1F - 2F * plane[0] * plane[0]);
        reflectionMat.m01 = (-2F * plane[0] * plane[1]);
        reflectionMat.m02 = (-2F * plane[0] * plane[2]);
        reflectionMat.m03 = (-2F * plane[3] * plane[0]);

        reflectionMat.m10 = (-2F * plane[1] * plane[0]);
        reflectionMat.m11 = (1F - 2F * plane[1] * plane[1]);
        reflectionMat.m12 = (-2F * plane[1] * plane[2]);
        reflectionMat.m13 = (-2F * plane[3] * plane[1]);

        reflectionMat.m20 = (-2F * plane[2] * plane[0]);
        reflectionMat.m21 = (-2F * plane[2] * plane[1]);
        reflectionMat.m22 = (1F - 2F * plane[2] * plane[2]);
        reflectionMat.m23 = (-2F * plane[3] * plane[2]);

        reflectionMat.m30 = 0F;
        reflectionMat.m31 = 0F;
        reflectionMat.m32 = 0F;
        reflectionMat.m33 = 1F;
    }
    #endregion
}
