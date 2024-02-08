using UnityEngine;
using UnityEngine.Rendering;

[System.Serializable, VolumeComponentMenu("TK_PostProcessing/SS_GlobalFog")]
public sealed class GlobalFog_Volume : VolumeComponent
{
    [Header("雾")]
    public ColorParameter _FogTint = new ColorParameter(Color.white, true);//如果有两个true,则为HDR设置
    public FloatParameter _FogIntensity = new FloatParameter(0);
    public FloatParameter _DistanceMax = new FloatParameter(10);
    public FloatParameter _DistanceMin = new FloatParameter(0);
    public FloatParameter _HeightMax = new FloatParameter(100);
    public FloatParameter _HeightMin = new FloatParameter(0);


    // [Header("散射")]
    // public ColorParameter _ScatteringTint = new ColorParameter(Color.white, true);//如果有两个true,则为HDR设置
    // public FloatParameter _ScatteringPower = new FloatParameter(10);
    // public FloatParameter _ScatteringIntensity = new FloatParameter(1);

    [Header("噪声")]
    //public Texture2DParameter Noise = new Texture2DParameter(Texture2D.redTexture);
    public FloatParameter _NoiseTilling = new FloatParameter(1);
    public FloatParameter _NoiseSpeed = new FloatParameter(1);
    public FloatParameter _NoiseIntensity = new FloatParameter(1);

    
}
