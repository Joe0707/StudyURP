using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]     //编辑器和运行模式都执行
[RequireComponent(typeof(Camera))]      //需要一个摄像机
public class PostEffectBase : MonoBehaviour
{
    #region 字段
    public Shader shader;
    protected Material material = null;
    #endregion

    #region 方法
    #region 虚方法
    protected virtual void OnRenderImage(RenderTexture src, RenderTexture dest) { }

    protected virtual void CheckedInfomation() { }
    #endregion

    #region 公共方法
    protected void CheckShaderAndCreateMaterial()
    {
        if(shader == null || !shader.isSupported)
        {
            Debug.Log("请挂载对应Shader，或Shader不支持");
            return;
        }
        material = new Material(shader);
        material.hideFlags = HideFlags.DontSave;
        Debug.Log(this.GetType().Name + "效果生效");
    }
    #endregion

    #endregion

    #region 生命周期

    public void Start()
    {
        if (this.GetType().Name == "PostEffectBase")
        {
            Debug.LogError("该脚本作为基类，不能挂载到场景中");
            DestroyImmediate(this);
            return;
        }
        CheckedInfomation();
        CheckShaderAndCreateMaterial();
    }

    #endregion
}
