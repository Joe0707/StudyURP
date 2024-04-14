using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ColorAdjustmentFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRendering;
        public Material material;
        public float _Brightness = 1;
        public float _Saturation = 1;
        public float _Contrast = 1;
        [Range(0.05f, 3.0f)]
        public float _VignetteIntensity = 1.5f;
        [Range(1.0f, 6.0f)]
        public float _VignetteRoundness = 5.0f;
        [Range(0.05f, 5.0f)]
        public float _VignetteSmoothness = 5.0f;
        [Range(0.0f, 1.0f)]
        public float _HueShift = 0.0f;

    }

    public Settings settings = new Settings();

    public class ColorAdjustmentRenderPass : ScriptableRenderPass
    {

        public Settings settings;
        RenderTargetIdentifier source;
        RenderTargetIdentifier destination;
        int temporaryRTId = Shader.PropertyToID("_TempRT");

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            base.OnCameraSetup(cmd, ref renderingData);
            source = renderingData.cameraData.renderer.cameraColorTarget;
            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            cmd.GetTemporaryRT(temporaryRTId, descriptor);
            destination = new RenderTargetIdentifier(temporaryRTId);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("ColorAdjustment");
            var material = settings.material;
            material.SetFloat("_Brightness", settings._Brightness);
            material.SetFloat("_Saturation", settings._Saturation);
            material.SetFloat("_Contrast", settings._Contrast);
            material.SetFloat("_VignetteIntensity", settings._VignetteIntensity);
            material.SetFloat("_VignetteRoundness", settings._VignetteRoundness);
            material.SetFloat("_VignetteSmoothness", settings._VignetteSmoothness);
            material.SetFloat("_HueShift", settings._HueShift);
            Blit(cmd, source, destination, material);
            Blit(cmd, destination, source);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

    ColorAdjustmentRenderPass colorAdjustmentPass;

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (settings.material == null)
        {
            Debug.LogError("Material NULL");
            return;
        }
        colorAdjustmentPass.settings = settings;
        colorAdjustmentPass.renderPassEvent = settings.renderPassEvent;
        renderer.EnqueuePass(colorAdjustmentPass);
    }

    public override void Create()
    {
        colorAdjustmentPass = new ColorAdjustmentRenderPass();
    }
}
