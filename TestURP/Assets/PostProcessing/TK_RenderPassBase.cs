using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

/// <summary>
/// 自定义的RenderPass基类，需要实现Render( )函数
/// </summary>
public class TK_RenderPassBase : ScriptableRenderPass
{
    #region 字段
    //接取屏幕原图的属性名
    protected static readonly int MainTexId = Shader.PropertyToID("_MainTex");
    //暂存贴图的属性名
    protected static readonly int TempTargetId = Shader.PropertyToID("_TempTargetColorTint");

    //CommandBuffer的名称
    protected string cmdName;
    //继承VolumeComponent的组件（父装子）
    protected VolumeComponent volume;
    //当前Pass使用的材质
    protected Material material;
    //当前渲染的目标
    protected RenderTargetIdentifier currentTarget;
    #endregion

    #region 函数
    //-------------------------构造------------------------------------
    /// <summary>
    /// 构造函数，用来初始化RenderPass
    /// </summary>
    /// <param name="evt"></param>
    /// <param name="shader"></param>
    public TK_RenderPassBase(RenderPassEvent evt, Shader shader)
    {
        cmdName = this.GetType().Name + "_cmdName";
        renderPassEvent = evt;//设置渲染事件位置
        //不存在则返回
        if (shader == null)
        {
            Debug.LogError("不存在" + this.GetType().Name + "shader");
            return;
        }
        material = CoreUtils.CreateEngineMaterial(shader);//新建材质
    }

    //----------------------子类继承但禁止重写---------------------------
    /// <summary>
    /// 设置渲染目标
    /// </summary>
    /// <param name="currentTarget"></param>
    public void Setup(in RenderTargetIdentifier currentTarget)
    {
        this.currentTarget = currentTarget;
    }
    /// <summary>
    /// 重写 Execute 
    /// 此函数相当于OnRenderImage，每帧都会被执行
    /// </summary>
    /// <param name="context"></param>
    /// <param name="renderingData"></param>
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        //材质是否存在
        if (material == null)
        {
            Debug.LogError("材质初始化失败");
            return;
        }
        //摄像机关闭后处理
        if (!renderingData.cameraData.postProcessEnabled)
        {
            //Debug.LogError("相机后处理是关闭的！！！");
            return;
        }

        var cmd = CommandBufferPool.Get(cmdName);//从池中获取CMD
        Render(cmd, ref renderingData);//将该Pass的渲染指令写入到CMD中
        context.ExecuteCommandBuffer(cmd);//执行CMD
        CommandBufferPool.Release(cmd);//释放CMD
        //Debug.Log("完成CMD");
    }

    //-----------------------子类必须重写----------------------------------
    /// <summary>
    /// 虚方法，供子类重写，需要将该Pass的具体渲染指令写入到CMD中
    /// </summary>
    /// <param name="cmd"></param>
    /// <param name="renderingData"></param>
    protected virtual void Render(CommandBuffer cmd, ref RenderingData renderingData) { }

    #endregion

}
