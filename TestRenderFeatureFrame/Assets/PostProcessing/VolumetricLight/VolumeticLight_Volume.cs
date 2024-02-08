using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[System.Serializable, VolumeComponentMenu("TK_PostProcessing/RayMarching_VolumeticLight")]
public class VolumeticLight_Volume : VolumeComponent
{
    [HideInInspector]
    public BoolParameter isActive = new BoolParameter(false);

    private void OnValidate()
    {
        isActive.value = active;
    }

    [Header("强度")]
    [Range(0, 1)]
    public FloatParameter intensity = new FloatParameter(0.7f);
    [Header("步进次数")]
    [Range(1, 64)]
    public FloatParameter stepTimes = new FloatParameter(16f);
    [Header("模糊范围")]
    [Range(0.1f, 10)]
    public FloatParameter blurRange = new FloatParameter(1f);
}
