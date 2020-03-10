﻿Shader "My Pipeline/Lit"
{
    Properties
    {
		_Color("Color", Color) = (1, 1, 1, 1)
		_MainTex("Albedo & Alpha", 2D) = "white" {}
		[Toggle(_CLIPPING)] _Clipping("Alpha Clipping", Float) = 0
		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
		[Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull", Float) = 2
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
		[Enum(Off, 0, On, 1)] _ZWrite("Z Write", Float) = 1
    }
    SubShader
    {
        
        Pass
        {
			Blend[_SrcBlend][_DstBlend]

			Cull[_Cull]
			ZWrite[_ZWrite]

			HLSLPROGRAM

			#pragma target 3.5
			#pragma multi_compile_instancing
			#pragma instancing_options assumeuniformscaling
			#pragma shader_feature _CLIPPING
			#pragma multi_compile _ _CASCADED_SHADOWS_HARD _CASCADED_SHADOWS_SOFT
			#pragma multi_compile _ _SHADOWS_HARD
			#pragma multi_compile _ _SHADOWS_SOFT

			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment

			#include "../ShaderLibrary/Lit.hlsl"

			ENDHLSL
        }

		Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}

			Blend[_SrcBlend][_DstBlend]
			Cull[_Cull]
			HLSLPROGRAM

			#pragma target 3.5

			#pragma multi_compile_instancing
			#pragma instancing_options assumeuniformscaling
			#pragma shader_feature _CLIPPING

			#pragma vertex ShadowCasterPassVertex
			#pragma fragment ShadowCasterPassFragment

			#include "../ShaderLibrary/ShadowCaster.hlsl"

			ENDHLSL
		}
    }
}
