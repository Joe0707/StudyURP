Shader "Unlit/GlobalFog_PostEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseMap ("Noise Map", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            Cull Off ZWrite Off ZTest Always

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 objectPos : TEXCOORD2;
                float3 realWorldPos : TEXCOORD1;
                float3 realViewPos :TEXCOORD3;
                float4 screen_uv : VAR_FUCK;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            float4 _FogTint;
            float _DistanceMax;
            float _DistanceMin;
            float _HeightMax;
            float _HeightMin;
            float _FogIntensity;

            float4 _ScatteringTint;
            float _ScatteringPower;
            float _ScatteringIntensity;

            TEXTURE2D(_NoiseMap);
            SAMPLER(sampler_NoiseMap);
            float _NoiseTilling;
            float _NoiseSpeed;
            float _NoiseIntensity;

            half4 _MainTex_TexelSize;
            TEXTURE2D_X_FLOAT(_CameraDepthTexture);
SAMPLER(    sampler_CameraDepthTexture);

            float3 DepthToWorldPositionV1(float2 screenPos)
            {
                //screenPos / screenPos.w就是【0,1】的归一化屏幕坐标  //_CameraDepthTexture是获取的深度图
                //Linear01Depth将采样的非线性深度图变成线性的
                float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos), _ZBufferParams);
                //将【0，1】映射到【-1， 1】上，得到ndcPos的x，y坐标
                float2 ndcPosXY = screenPos * 2 - 1;
                //float3的z值补了一个1，代表远平面的NDC坐标    _ProjectionParams代表view空间的远平面, 我们知道裁剪空间的w和view空间的z相等，相当于做了一次逆向透视除法，得到了远平面的clipPos
                float3 clipPos = float3(ndcPosXY.x, ndcPosXY.y, 1) * _ProjectionParams.z;
                //clipPos.z = -clipPos.z;
                //return clipPos;
                float3 viewPos = mul(unity_CameraInvProjection, clipPos.xyzz).xyz * depth;  //远平面的clipPos转回远平面的viewPos， 再利用depth获取该点在viewPos里真正的位置
                //return viewPos;
                //补一个1变成其次坐标，然后逆的V矩阵变回worldPos
                viewPos.z = -viewPos.z;
                float3 worldPos = mul(unity_CameraToWorld, float4(viewPos, 1)).xyz;
                return worldPos;
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                o.objectPos = v.vertex;
                o.pos = TransformObjectToHClip(v.vertex);
                o.realWorldPos = mul(unity_ObjectToWorld, v.vertex);
                o.realViewPos = mul(UNITY_MATRIX_MV, v.vertex);
                o.screen_uv = ComputeScreenPos(o.pos);
                o.uv.xy = v.texcoord;
                o.uv.zw = v.texcoord;
                #if UNITY_UV_STARTS_AT_TOP
                if(_MainTex_TexelSize.y < 0)
                {
                    o.uv.w = 1 - o.uv.w;
                }
                #endif

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half3 worldPos = DepthToWorldPositionV1(i.uv);
                
             //Noise扰动
	            half2 uv_tillingAndSpeed = worldPos.xz * _NoiseTilling * 0.01   +   _Time * _NoiseSpeed * 0.1;	//缩放
	            half noise = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, uv_tillingAndSpeed).r * _NoiseIntensity;
	            noise = noise * 2 - 1;	//0-1映射到-1 1上，让对比度更大，扰动感更明显

            //Fog
	            //距离雾
	            half dis = distance(worldPos, _WorldSpaceCameraPos) + noise;	//距离值，加扰动
	            half fogDisFactor = saturate((dis - _DistanceMin) / (_DistanceMax - _DistanceMin));	//重映射到0，1
	            //高度雾
	            half height = worldPos.y - _WorldSpaceCameraPos.y + noise;
	            half fogHgFactor = saturate((height - _HeightMin) / (_HeightMax - _HeightMin));
	            //Fog因子混合
	            half fog = saturate((fogDisFactor * fogHgFactor) * _FogIntensity);	//让距离雾的效果不受高度雾影响，但高度雾受距离雾影响

            // //散射
	           //  half3 worldViewDir = normalize(TransformWorldToViewDir(worldPos));
            //     Light light = GetMainLight();
	           //  half3 worldLightDir_INVERSE = normalize(light.direction);
            //     //return half4(worldLightDir_INVERSE, 1);
	           //  half scattering = _ScatteringIntensity * pow(saturate(dot(worldViewDir, worldLightDir_INVERSE)), _ScatteringPower);
	           //  //power控制散射范围，intensity控制强度。当worldViewDir 和 worldLightDir_INVERSE 夹角越小，散射程度越大
	           //  //散射混合Fog因子的衰减
	           //  scattering = scattering *  fog;

            //颜色插值
	            //雾的颜色 与 散射颜色插值
	            //half3 fogAndScatteringColor = lerp(_FogTint, _ScatteringTint, scattering);

                //half4 final_fog = half4(fogAndScatteringColor, fog);
                half4 final_fog = _FogTint * fog;

                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                //return 1;
                //return half4(worldPos, 1);
                return final_fog * fog + (1 - fog) * col;
            }
            ENDHLSL
        }
        
    }
}
