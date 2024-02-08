using System.Collections;
using System.Collections.Generic;
using System.IO;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GlobalFog_RenderPass : TK_RenderPassBase
{
    public Texture2D noiseMap = new Texture2D(1024, 1024);
    public GlobalFog_RenderPass(RenderPassEvent evt, Shader shader) : base(evt, shader)
    {
        Debug.Log("初始化：" + this.GetType().Name);
        Debug.Log(Application.persistentDataPath + "/Texture/PostProcessing/Noise.png");
        Debug.Log(Application.dataPath);
        //byte[] temp = File.ReadAllBytes(Application.persistentDataPath + "/Texture/PostProcessing/Noise.png");
        byte[] temp = File.ReadAllBytes(Application.dataPath + "/Noise.png");
        noiseMap.LoadImage(temp);
        noiseMap.Apply();
        noiseMap.hideFlags = HideFlags.DontSave;    //保留对象到新场景中，避免了切场景后，图片内容丢失。但小心内存泄漏
        Debug.Log(noiseMap);
    }

    protected override void Render(CommandBuffer cmd, ref RenderingData renderingData)
    {
        //【获取对应的VolumeComponent】
        var stack = VolumeManager.instance.stack;//传入volume数据
        volume = stack.GetComponent<GlobalFog_Volume>();//拿到我们的Volume
        if (volume == null)
        {
            Debug.LogError("Volume组件获取失败");
            return;
        }

        ref var cameraData = ref renderingData.cameraData;//汇入摄像机数据
        var camera = cameraData.camera;//传入摄像机数据
        var source = currentTarget;//当前渲染图片汇入

        material.SetColor("_FogTint", ((GlobalFog_Volume)volume)._FogTint.value);
        material.SetFloat("_DistanceMax", ((GlobalFog_Volume)volume)._DistanceMax.value);
        material.SetFloat("_DistanceMin", ((GlobalFog_Volume)volume)._DistanceMin.value);
        material.SetFloat("_HeightMax", ((GlobalFog_Volume)volume)._HeightMax.value);
        material.SetFloat("_HeightMin", ((GlobalFog_Volume)volume)._HeightMin.value);
        material.SetFloat("_FogIntensity", ((GlobalFog_Volume)volume)._FogIntensity.value);

        // material.SetColor("_ScatteringTint", ((GlobalFog_Volume)volume)._ScatteringTint.value);
        // material.SetFloat("_ScatteringPower", ((GlobalFog_Volume)volume)._ScatteringPower.value);
        // material.SetFloat("_ScatteringIntensity", ((GlobalFog_Volume)volume)._ScatteringIntensity.value);
        material.SetTexture("_NoiseMap", noiseMap);
        //Debug.Log((material.GetTexture("_NoiseMap") as Texture2D).GetPixel(100, 100));
        material.SetFloat("_NoiseTilling", ((GlobalFog_Volume)volume)._NoiseTilling.value);
        material.SetFloat("_NoiseSpeed", ((GlobalFog_Volume)volume)._NoiseSpeed.value);
        material.SetFloat("_NoiseIntensity", ((GlobalFog_Volume)volume)._NoiseIntensity.value);

        
        cmd.SetGlobalTexture(MainTexId, source);   //汇入当前渲染图片，因为这个cmd是跑在RenderPass中的，所以只对当前Pass的_MainTex起效果
        cmd.GetTemporaryRT(TempTargetId1, cameraData.camera.scaledPixelWidth, cameraData.camera.scaledPixelHeight, 0, FilterMode.Trilinear, RenderTextureFormat.Default);//设置目标贴图
        cmd.Blit(source, TempTargetId1);     //将source复制到临时的一份RT上去
        cmd.Blit(TempTargetId1, source, material, 0);    //临时RT经过处理之后，再传回source上

    }
}
