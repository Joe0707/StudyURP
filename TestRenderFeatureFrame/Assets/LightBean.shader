// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "LightBean"
{
	Properties
	{
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode", Float) = 0
		_LightColor("LightColor", Color) = (0,0,0,0)
		_LightIntensity("LightIntensity", Float) = 1
		_F_Power("F_Power", Float) = 1
		_F_Scale("F_Scale", Float) = 1
		_F_Bias("F_Bias", Float) = 0
		_NoiseMap("NoiseMap", 2D) = "white" {}
		_NoiseSpeed("NoiseSpeed", Vector) = (0,0,0,0)
		_FadeOffset("FadeOffset", Float) = 0
		_FadePower("FadePower", Float) = 1
		_EndAngle("EndAngle", Float) = 0
		_StartAngle("StartAngle", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IsEmissive" = "true"  }
		Cull [_CullMode]
		ZWrite Off
		Blend SrcAlpha One
		
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		struct Input
		{
			float2 uv_texcoord;
			float3 worldNormal;
			float3 viewDir;
		};

		uniform float _CullMode;
		uniform float _EndAngle;
		uniform float _StartAngle;
		uniform float4 _LightColor;
		uniform float _LightIntensity;
		uniform sampler2D _NoiseMap;
		uniform float2 _NoiseSpeed;
		uniform float4 _NoiseMap_ST;
		uniform float _F_Power;
		uniform float _F_Scale;
		uniform float _F_Bias;
		uniform float _FadeOffset;
		uniform float _FadePower;

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float3 ase_vertexNormal = v.normal.xyz;
			float3 VertexOffset40 = ( ( ase_vertexNormal * v.texcoord.xy.x * _EndAngle ) + ( ase_vertexNormal * ( 1.0 - v.texcoord.xy.x ) * _StartAngle ) );
			v.vertex.xyz += VertexOffset40;
		}

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float2 uv0_NoiseMap = i.uv_texcoord * _NoiseMap_ST.xy + _NoiseMap_ST.zw;
			float2 panner23 = ( 1.0 * _Time.y * _NoiseSpeed + uv0_NoiseMap);
			o.Emission = ( _LightColor * _LightIntensity * tex2D( _NoiseMap, panner23 ).r ).rgb;
			float3 ase_worldNormal = i.worldNormal;
			float dotResult6 = dot( ase_worldNormal , i.viewDir );
			float Fresnel17 = saturate( ( ( pow( abs( dotResult6 ) , _F_Power ) * _F_Scale ) + _F_Bias ) );
			o.Alpha = ( Fresnel17 * pow( ( ( 1.0 - i.uv_texcoord.x ) - _FadeOffset ) , _FadePower ) );
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Unlit keepalpha fullforwardshadows vertex:vertexDataFunc 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				o.worldNormal = worldNormal;
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.viewDir = worldViewDir;
				surfIN.worldNormal = IN.worldNormal;
				SurfaceOutput o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutput, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=17800
1946;237;1416;798;925.3897;224.9145;1.3;True;False
Node;AmplifyShaderEditor.CommentaryNode;15;-1663.871,-660.4091;Inherit;False;1362.844;409.5919;Comment;12;16;12;11;14;13;10;9;6;5;4;17;49;Fresnel;1,1,1,1;0;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;5;-1598.086,-444.9052;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;4;-1630.871,-607.4091;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;6;-1379.786,-513.6052;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;49;-1249.218,-514.0795;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;10;-1237.985,-416.3053;Inherit;False;Property;_F_Power;F_Power;4;0;Create;True;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;14;-1022.19,-402.9656;Inherit;False;Property;_F_Scale;F_Scale;5;0;Create;True;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;9;-1079.386,-495.6053;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;41;-1333.577,1081.485;Inherit;False;960.9911;499.991;利用UV来进行不同程度的偏移;9;40;56;39;34;54;55;38;37;58;调整开合角度;1,1,1,1;0;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;34;-1310.577,1300.559;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;12;-876.9117,-386.9729;Inherit;False;Property;_F_Bias;F_Bias;6;0;Create;True;0;0;False;0;0;-0.51;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;13;-904.8834,-496.3763;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;33;-1334.311,713.4068;Inherit;False;829.2988;284.7537;Comment;6;26;29;27;28;31;30;上部消隐（软边缘）;1,1,1,1;0;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;26;-1284.313,763.4068;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;11;-760.6912,-495.5902;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-1053.221,1102.076;Inherit;False;Property;_EndAngle;EndAngle;11;0;Create;True;0;0;False;0;0;0.07;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;37;-1254.838,1143.786;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;56;-1036.409,1479.881;Inherit;False;Property;_StartAngle;StartAngle;12;0;Create;True;0;0;False;0;0;-0.18;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;54;-1080.409,1342.881;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;38;-894.804,1181.571;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector2Node;25;-1151.414,376.1525;Inherit;False;Property;_NoiseSpeed;NoiseSpeed;8;0;Create;True;0;0;False;0;0,0;0.02,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SaturateNode;16;-626.8628,-490.475;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;22;-1220.395,231.6082;Inherit;False;0;21;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;27;-1044.39,781.8043;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;55;-896.4092,1314.881;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;29;-1026.214,873.7605;Inherit;False;Property;_FadeOffset;FadeOffset;9;0;Create;True;0;0;False;0;0;0.01;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;58;-722.4092,1265.881;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;17;-484.265,-492.1725;Inherit;False;Fresnel;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;31;-831.2141,882.7605;Inherit;False;Property;_FadePower;FadePower;10;0;Create;True;0;0;False;0;1;1.79;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;23;-944.4147,234.1528;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;28;-862.7905,781.8045;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;18;-690.9596,515.875;Inherit;True;17;Fresnel;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;2;-571.3,123.4;Inherit;False;Property;_LightIntensity;LightIntensity;3;0;Create;True;0;0;False;0;1;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;1;-604.3,-48.59999;Inherit;False;Property;_LightColor;LightColor;2;0;Create;True;0;0;False;0;0,0,0,0;1,0.9098039,0.695,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;21;-689.3448,216.0211;Inherit;True;Property;_NoiseMap;NoiseMap;7;0;Create;True;0;0;False;0;-1;None;2e9ce30931ab98c4792d4c451abba6f1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;40;-557.3854,1230.695;Inherit;False;VertexOffset;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PowerNode;30;-682.214,783.7605;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;42;-65.00469,411.5245;Inherit;False;40;VertexOffset;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-1283.044,1644.932;Inherit;False;Property;_CullMode;Cull Mode;0;1;[Enum];Create;True;0;1;UnityEngine.Rendering.CullMode;True;0;0;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;3;-363.3,42.39999;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;32;-400.696,563.7441;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;184.9571,-15.05464;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;LightBean;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Off;2;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;True;0;True;Transparent;;Transparent;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;8;5;False;-1;1;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;1;-1;-1;-1;0;False;0;0;True;47;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;6;0;4;0
WireConnection;6;1;5;0
WireConnection;49;0;6;0
WireConnection;9;0;49;0
WireConnection;9;1;10;0
WireConnection;13;0;9;0
WireConnection;13;1;14;0
WireConnection;11;0;13;0
WireConnection;11;1;12;0
WireConnection;54;0;34;1
WireConnection;38;0;37;0
WireConnection;38;1;34;1
WireConnection;38;2;39;0
WireConnection;16;0;11;0
WireConnection;27;0;26;1
WireConnection;55;0;37;0
WireConnection;55;1;54;0
WireConnection;55;2;56;0
WireConnection;58;0;38;0
WireConnection;58;1;55;0
WireConnection;17;0;16;0
WireConnection;23;0;22;0
WireConnection;23;2;25;0
WireConnection;28;0;27;0
WireConnection;28;1;29;0
WireConnection;21;1;23;0
WireConnection;40;0;58;0
WireConnection;30;0;28;0
WireConnection;30;1;31;0
WireConnection;3;0;1;0
WireConnection;3;1;2;0
WireConnection;3;2;21;1
WireConnection;32;0;18;0
WireConnection;32;1;30;0
WireConnection;0;2;3;0
WireConnection;0;9;32;0
WireConnection;0;11;42;0
ASEEND*/
//CHKSM=37C076148D159F4CE797B0C573E549955A4C219D