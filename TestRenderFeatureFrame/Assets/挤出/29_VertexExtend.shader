Shader "Unlit/001_Lambert"
{
	Properties
	{
		_MainTex("_MainTex", 2D) = "white"{}
		_Diffuse("Diffuse", Color) = (1, 1, 1, 1)
		_ExtendDistance("Extend Distance", float) = 1.0
		_Color("_Color", Color) = (1, 1, 1, 1)
		_Intensity("_Intensity", float) = 1.0
		_PowFactor("_PowFactor", float) = 1.0
	}

	SubShader
	{
		pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			Cull off

			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
			
				#include "Lighting.cginc"

				fixed4 _Diffuse;

				struct appdata
				{
					float4 vertex : POSITION;
					float3 normal : NORMAL;
				};

				struct v2f
				{
					float4 pos : SV_POSITION;
					fixed3 col : COLOR;
				};

				v2f vert(appdata i)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(i.vertex);
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
					//fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
					//fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.vertex);
					//fixed3 worldLightDir = -normalize(_WorldSpaceLightPos0.xyz - i.vertex);
					fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.vertex));
					fixed3 worldNormal = UnityObjectToWorldNormal(i.normal);
					fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldLightDir, worldNormal));
					o.col = ambient + diffuse;
					return o;
				}

				fixed4 frag(v2f i) : SV_TARGET0
				{
					return fixed4(i.col, 1);
				}

			ENDCG
		}
		
		pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off ZWrite Off 
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 objectPos : TEXCOORD1;
			};

			float _ExtendDistance;
			sampler2D _MainTex;
			float4 _Color;
			float _Intensity;
			float _PowFactor;
			
			//1.模型背面沿着背光方向挤出一定强度
			v2f vert(appdata v)
			{
				v2f o;
				float3 dir = ObjSpaceLightDir(v.vertex);
				float NdotL = dot(dir, v.normal);
				//sign,确认符号，负为-1，正为1，零为0
				float extrude = sign(NdotL) * 0.5 + 0.5;
				o.objectPos = v.vertex;
				v.vertex.xyz -= dir * extrude * _ExtendDistance;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			//2.片元阶段控制衰减值，从而让挤出的部分呈现丁达尔效应
			half4 frag(v2f i) : SV_Target
			{
				fixed4 mainColor = tex2D(_MainTex, i.uv);
				float atten = 1 / (1 + length(i.objectPos));
				fixed4 finalColor = pow(min(1,  mainColor * _Color * atten * _Intensity), _PowFactor);
				return finalColor;
			}
			ENDCG

		}
	}
	FallBack "Diffuse"
}
