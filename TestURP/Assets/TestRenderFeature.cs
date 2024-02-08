using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.Universal.Internal;

public class TestRenderFeature : ScriptableRendererFeature
{
    [Serializable]
    public class RenderObjectsSettings
    {
        public RenderPassEvent Event = RenderPassEvent.AfterRenderingOpaques;

        public RenderObjects.FilterSettings filterSettings = new RenderObjects.FilterSettings();
    }

    public RenderObjectsSettings settings = new RenderObjectsSettings();

    private TestRenderPass pass;

    private RenderTargetHandle m_TestTarget;
    
    public override void Create()
    {
        pass = new TestRenderPass(settings);
        m_TestTarget = new RenderTargetHandle();
        m_TestTarget.Init("_TestInfoTexture");
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        pass.Setup(m_TestTarget);
        renderer.EnqueuePass(pass);
    }

    public class TestRenderPass : ScriptableRenderPass
    {
        private RenderTargetHandle targetHandle;

        private const string ProfilerName = "TestPass";

        private ProfilingSampler _sampler = new ProfilingSampler(ProfilerName);

        private List<ShaderTagId> m_Shaders = new List<ShaderTagId>();

        RenderQueueType renderQueueType;

        private FilteringSettings m_FilteringSettings;

        private RenderTargetIdentifier rtactive;
        private RenderTargetIdentifier curColorRT;
        private RenderTargetIdentifier curDepthRT;
        private ScriptableRenderer m_curRenderer;

        public TestRenderPass(RenderObjectsSettings setting)
        {
            m_Shaders.Add(new ShaderTagId("TestInfo"));
            this.renderPassEvent = setting.Event;
            this.renderQueueType = setting.filterSettings.RenderQueueType;

            RenderQueueRange renderQueueRange = (renderQueueType == RenderQueueType.Transparent)
                ? RenderQueueRange.transparent
                : RenderQueueRange.opaque;
            m_FilteringSettings = new FilteringSettings(renderQueueRange, setting.filterSettings.LayerMask);
        }

        public void Setup(RenderTargetHandle target)
        {
            targetHandle = target;
        }
        

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            RenderTextureDescriptor des = renderingData.cameraData.cameraTargetDescriptor;
            des.depthBufferBits = 0;
            des.colorFormat = RenderTextureFormat.R8;
            cmd.GetTemporaryRT(targetHandle.id, des);
            ConfigureTarget( targetHandle.Identifier(),renderingData.cameraData.renderer.cameraDepthTarget);
            ConfigureClear(ClearFlag.Color, Color.white);
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            // cameraTextureDescriptor.depthBufferBits = 0;
            // cameraTextureDescriptor.colorFormat = RenderTextureFormat.R8;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var drawSettings = CreateDrawingSettings(m_Shaders, ref renderingData,
                renderingData.cameraData.defaultOpaqueSortFlags);
            var cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, _sampler))
            {
                // //拷贝深度缓冲
                // // cmd.CopyTexture(BuiltinRenderTextureType.CurrentActive,rth.id);
                // var color = RenderTexture.active.colorBuffer;
                // var depth = RenderTexture.active.depthBuffer;
                // cmd.SetRenderTarget(rth.Identifier(),RenderBufferLoadAction.DontCare,RenderBufferStoreAction.Store,Shader.PropertyToID("_CameraDepthTexture"),RenderBufferLoadAction.Load,RenderBufferStoreAction.Store);
                // cmd.ClearRenderTarget(false,true,Color.white);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref m_FilteringSettings);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(targetHandle.id);
        }
    }
}