using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class TK_PostProcessing_RenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public string RenderPassName;
        //指定该RendererFeature在渲染流程的哪个时机插入
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        //指定一个shader
        public Shader shader;
        //是否开启
        public bool activeff;

        public TK_RenderPassBase renderPass;
    }
    public Settings[] settings;//开放设置

    /// <summary>
    /// 当RenderFeature参数面板修改时调用，利用类名 + 反射实例化RenderPass
    /// </summary>
    public override void Create()
    {
        if(settings != null && settings.Length > 0)
        {
            for(int i = 0; i < settings.Length; i++)
            {
                if (settings[i].activeff && settings[i].shader != null)
                {
                    Debug.Log("Create" + i);
                    //try
                    //{
                        settings[i].renderPass = Activator.CreateInstance(Type.GetType(settings[i].RenderPassName), settings[i].renderPassEvent, settings[i].shader) as TK_RenderPassBase;
                    //}
                    //catch (Exception e)
                    //{
                    //    Debug.Log(e.Message + "后处理C#脚本名有误，请检查RenderPassName   :" + settings[i].RenderPassName);
                    //}
                }
            }
        }
    }

    /// <summary>
    /// 将RenderPass注入到Render中
    /// </summary>
    /// <param name="renderer"></param>
    /// <param name="renderingData"></param>
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if(settings != null && settings.Length > 0)
        {
            for (int i = 0; i < settings.Length; i++)
            {
                if(settings[i].activeff && settings[i].renderPass != null)
                {
                    //Debug.Log("注入" + i);
                    settings[i].renderPass.Setup(renderer.cameraColorTarget);   //设置渲染对象
                    renderer.EnqueuePass(settings[i].renderPass);   //注入Render的渲染队列
                }
            }
        }
    }
}
