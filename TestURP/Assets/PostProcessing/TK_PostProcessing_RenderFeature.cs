using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class TK_PostProcessing_RenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public string RenderPassName;
        //ָ����RendererFeature����Ⱦ���̵��ĸ�ʱ������
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        //ָ��һ��shader
        public Shader shader;
        //�Ƿ���
        public bool activeff;

        public TK_RenderPassBase renderPass;
    }
    public Settings[] settings;//��������

    /// <summary>
    /// ��RenderFeature��������޸�ʱ���ã��������� + ����ʵ����RenderPass
    /// </summary>
    public override void Create()
    {
        Debug.Log(11111);
        Debug.Log(settings[0].renderPass == null);
        //if(settings != null && settings.Length > 0)
        //{
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
                    //    Debug.Log(e.Message + "����C#�ű�����������RenderPassName   :" + settings[i].RenderPassName);
                    //}
                }
            //}
        }
    }

    /// <summary>
    /// ��RenderPassע�뵽Render��
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
                    //Debug.Log("ע��" + i);
                    settings[i].renderPass.Setup(renderer.cameraColorTarget);   //������Ⱦ����
                    renderer.EnqueuePass(settings[i].renderPass);   //ע��Render����Ⱦ����
                }
            }
        }
    }
}
