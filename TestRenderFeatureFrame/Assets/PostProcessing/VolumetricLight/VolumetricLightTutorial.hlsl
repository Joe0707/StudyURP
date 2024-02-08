#ifndef VOLUME_LIGHT
#define VOLUME_LIGHT

#define MAIN_LIGHT_CALCULATE_SHADOWS  //定义阴影采样
#define _MAIN_LIGHT_SHADOWS_CASCADE //启用级联阴影(详见图解3)
//若项目中使用了级联阴影，_MAIN_LIGHT_SHADOWS_CASCADE 这个宏必须要有。
//如果不定义，你就会发现在特定情况下，如右图一般的严重漏光现象。
//此现象发生的本质原因是，右侧像素已经超过一级级联的采样范围（这里是10m），如果不定义宏，那么永远返回第一级级联，然后采样结果错误。
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl" 
#include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" 
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"


#define random(seed) sin(seed * 641.5467987313875 + 1.943856175)
#define MAX_RAY_LENGTH 20

struct Varings
{
    float3 positionOS : POSITION;
    float2 uv : TEXCOORD0;
};
struct Output
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 viewVec : TEXCOORD1;
};

float _RandomNumber;
float _Intensity;
float _StepTime;

TEXTURE2D(_MainTex);
TEXTURE2D(_LightTex);

SAMPLER(sampler_MainTex);
SAMPLER(sampler_LightTex);

Output vert(Varings v)
{
    Output o;
    o.positionCS = TransformObjectToHClip(v.positionOS);
    o.uv = v.uv;

    float3 ndcPos = float3(v.uv.xy * 2.0 - 1.0, 1); //直接把uv映射到ndc坐标
    float far = _ProjectionParams.z; //获取投影信息的z值，代表远平面距离
    float3 clipVec = float3(ndcPos.x, ndcPos.y, ndcPos.z * -1) * far; //裁切空间下的视锥顶点坐标
    o.viewVec = mul(unity_CameraInvProjection, clipVec.xyzz).xyz; //观察空间下的视锥向量

    return o;
}
float3 GetWorldPosition(float2 uv, float3 viewVec, out float depth, out float linearDepth)
{
    depth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture,sampler_CameraDepthTexture,uv).r;//采样深度图
    depth = Linear01Depth(depth, _ZBufferParams); //转换为线性深度
    linearDepth = LinearEyeDepth(depth,_ZBufferParams);
    float3 viewPos = viewVec * depth; //获取实际的观察空间坐标（插值后）
    float3 worldPos = mul(unity_CameraToWorld, float4(viewPos,1)).xyz; //观察空间-->世界空间坐标
    return worldPos;
}
float GetLightAttenuation(float3 position)
{
    float4 shadowPos = TransformWorldToShadowCoord(position); //把采样点的世界坐标转到阴影空间
    float intensity = MainLightRealtimeShadow(shadowPos); //进行shadow map采样
    return intensity; //返回阴影值
}
half4 blendFrag(Output i): SV_TARGET
{
    half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
    half4 lightColor = SAMPLE_TEXTURE2D(_LightTex, sampler_LightTex, i.uv);
    return sceneColor + sceneColor * lightColor;
}
half4 frag(Output i) : SV_TARGET
{
    float depth = 0;
    float linearDepth = 0;
    float3 worldPos = GetWorldPosition(i.uv, i.viewVec, depth, linearDepth); //像素的世界坐标
    float3 startPos = _WorldSpaceCameraPos; //摄像机上的世界坐标
    float3 dir = normalize(worldPos - startPos); //视线方向
    float rayLength = length(worldPos - startPos); //视线长度

    rayLength = min(rayLength, linearDepth); //裁剪被遮挡片元
    rayLength = min(rayLength, MAX_RAY_LENGTH); //限制最大步进长度，MAX_RAY_LENGTH这里设置为20

    float3 final = startPos + dir * rayLength; //定义步进结束点
    float2 step = 1.0 / _StepTime;  //根据步进次数 获取步长
    step.y *= 0.4;
    float seed = random((_ScreenParams.y * i.uv.y + i.uv.x) * _ScreenParams.x + _RandomNumber);
    half3 intensity = 0; //累计光强
    //一直步进到物体的表面，而在这个过程中，一直采样ShadowMap，累积光强
    //然后再与原本的场景混合，即可达到体积光的效果。但为了效果好看，还可以做一些模糊处理（参考图解1）
    for(float i = step.x; i < 1; i += step.x)
    {
        //引入随机数，造成采样时的抖动，防止因为等距采样造成的光强为0的误差（参考图解2）
        seed = random(seed);
        float3 currentPosition = lerp(startPos, final, i + seed * step.y);
        float atten = GetLightAttenuation(currentPosition) * _Intensity; //阴影采样，_Intensity为强度因子
        float3 light = atten; 
        intensity += light; 
    }
    intensity /= _StepTime;

    Light mainLight = GetMainLight(); //引入场景灯光数据
    if(depth > 0.999) //这里做一个远视强度限制。
    {
        intensity = 0;
    }
    return half4(mainLight.color * intensity,1);
}
#endif