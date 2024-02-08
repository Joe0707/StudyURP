using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class VolumetricLight_RenderPass : TK_RenderPassBase
{

    public VolumetricLight_RenderPass(RenderPassEvent evt, Shader shader) : base(evt, shader)
    {
        Debug.Log("初始化VolumetricLight_RenderPass");
    }

    protected override void Render(CommandBuffer cmd, ref RenderingData renderingData)
    {
        //【获取对应的VolumeComponent】
        var stack = VolumeManager.instance.stack;//传入volume数据
        volume = stack.GetComponent<VolumeticLight_Volume>();//拿到我们的Volume
        if (volume == null)
        {
            Debug.LogError("VolumeticLight_Volume组件获取失败");
            return;
        }
        VolumeticLight_Volume v = volume as VolumeticLight_Volume;
        if (!v.isActive.value) return;
        ref var cameraData = ref renderingData.cameraData;//汇入摄像机数据
        var source = currentTarget;//当前渲染图片汇入


        material.SetFloat("_RandomNumber", Random.Range(0.0f, 1.0f));
        material.SetFloat("_Intensity", v.intensity.value);
        material.SetFloat("_StepTime", v.stepTimes.value);

        cmd.GetTemporaryRT(TempTargetId1, cameraData.camera.scaledPixelWidth, cameraData.camera.scaledPixelHeight, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);//设置目标贴图
        cmd.GetTemporaryRT(TempTargetId2, cameraData.camera.scaledPixelWidth, cameraData.camera.scaledPixelHeight, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);//设置目标贴图

        //体积光光线步进
        cmd.Blit(currentTarget, TempTargetId1, material, 0);
        //cmd.Blit(TempTargetId1, currentTarget);

        //Kawase模糊
        var width = cameraData.camera.scaledPixelWidth / 2;
        var height = cameraData.camera.scaledPixelHeight / 2;
        var blurRange = v.blurRange.value;

        for (int i = 0; i < 4; i++)
        {
            material.SetFloat("_BlurRange", (i + 1) * blurRange);
            cmd.Blit(TempTargetId1, TempTargetId2, material, 1);
            cmd.Blit(TempTargetId2, TempTargetId1, material, 1);
        }
        cmd.SetGlobalTexture("_LightTex", TempTargetId2);

        ////blit 混合
        cmd.Blit(currentTarget, TempTargetId1, material, 2);
        cmd.Blit(TempTargetId1, currentTarget);

        cmd.ReleaseTemporaryRT(TempTargetId1);
        cmd.ReleaseTemporaryRT(TempTargetId2);
    }
}
