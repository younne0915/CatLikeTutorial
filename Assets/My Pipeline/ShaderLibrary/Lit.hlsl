﻿#ifndef MYRP_LIT_INCLUDED
#define MYRP_LIT_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"

#include "Lighting.hlsl"

CBUFFER_START(UnityPerFrame)
float4x4 unity_MatrixVP;
float4 _DitherTexture_ST;
CBUFFER_END

//为了让着色器兼容SRP，所有内置引擎属性必须在名为“UnityPerDraw”的CBUFFER中声明
CBUFFER_START(UnityPerDraw)
float4x4 unity_ObjectToWorld, unity_WorldToObject;
float4 unity_LODFade;
//该物体(顶点、片元)受到几个灯光影响
float4 unity_LightIndicesOffsetAndCount;
//受到影响的灯光的下标
float4 unity_4LightIndices0, unity_4LightIndices1;
float4 unity_ProbesOcclusion;
float4 unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax;
float4 unity_SpecCube0_ProbePosition, unity_SpecCube0_HDR;
float4 unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax;
float4 unity_SpecCube1_ProbePosition, unity_SpecCube1_HDR;
float4 unity_LightmapST, unity_DynamicLightmapST;
float4 unity_SHAr, unity_SHAg, unity_SHAb;
float4 unity_SHBr, unity_SHBg, unity_SHBb;
float4 unity_SHC;
CBUFFER_END

CBUFFER_START(UnityPerMaterial)
float4 _MainTex_ST;
float _Cutoff;
//float _Smoothness;
CBUFFER_END

#define MAX_VISIBLE_LIGHTS 16

CBUFFER_START(_LightBuffer)
float4 _VisibleLightColors[MAX_VISIBLE_LIGHTS];
float4 _VisibleLightDirectionsOrPositions[MAX_VISIBLE_LIGHTS];
float4 _VisibleLightAttenuations[MAX_VISIBLE_LIGHTS];
float4 _VisibleLightSpotDirections[MAX_VISIBLE_LIGHTS];
float4 _VisibleLightOcclusionMasks[MAX_VISIBLE_LIGHTS];
CBUFFER_END

CBUFFER_START(_ShadowBuffer)
//float4x4 _WorldToShadowMatrix;
//float _ShadowStrength;
float4x4 _WorldToShadowMatrices[MAX_VISIBLE_LIGHTS];
float4x4 _WorldToShadowCascadeMatrices[5];
float4 _CascadeCullingSpheres[4];
float4 _ShadowData[MAX_VISIBLE_LIGHTS];
float4 _ShadowMapSize;
float4 _CascadedShadowMapSize;
float4 _GlobalShadowData;
float _CascadedShadowStrength;
float4 _SubtractiveShadowColor;
CBUFFER_END

CBUFFER_START(UnityPerCamera)
float3 _WorldSpaceCameraPos;
CBUFFER_END

CBUFFER_START(UnityProbeVolume)
float4 unity_ProbeVolumeParams;
float4x4 unity_ProbeVolumeWorldToObject;
float3 unity_ProbeVolumeSizeInv;
float3 unity_ProbeVolumeMin;
CBUFFER_END

TEXTURE3D_FLOAT(unity_ProbeVolumeSH);
SAMPLER(samplerunity_ProbeVolumeSH);

TEXTURE2D_SHADOW(_ShadowMap);
SAMPLER_CMP(sampler_ShadowMap);

TEXTURE2D_SHADOW(_CascadedShadowMap);
SAMPLER_CMP(sampler_CascadedShadowMap);


TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);


TEXTURECUBE(unity_SpecCube0);
TEXTURECUBE(unity_SpecCube1);
SAMPLER(samplerunity_SpecCube0);

TEXTURE2D(unity_Lightmap);
SAMPLER(samplerunity_Lightmap);

TEXTURE2D(unity_DynamicLightmap);
SAMPLER(samplerunity_DynamicLightmap);

TEXTURE2D(unity_ShadowMask);
SAMPLER(samplerunity_ShadowMask);

TEXTURE2D(_DitherTexture);
SAMPLER(sampler_DitherTexture);

#define UNITY_MATRIX_M unity_ObjectToWorld
#define UNITY_MATRIX_I_M unity_WorldToObject

#if !defined(LIGHTMAP_ON)
#if defined(_SHADOWMASK)|| defined(_DISTANCE_SHADOWMASK)|| \
		defined(_SUBTRACTIVE_LIGHTING)
#define SHADOWS_SHADOWMASK
#endif
#endif
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"


//声明一个数组PerInstanceArray，里面存储float4, _Color
UNITY_INSTANCING_BUFFER_START(PerInstance)
UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
UNITY_INSTANCING_BUFFER_END(PerInstance)



struct VertexInput {
	float4 pos : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
#if defined(LIGHTMAP_ON)
	float2 lightmapUV : TEXCOORD1;
#endif
#if defined(DYNAMICLIGHTMAP_ON)
	float2 dynamicLightmapUV : TEXCOORD2;
#endif
	//声明一个instanceID，当GPU Instance可用时，获取该顶点对应的M 矩阵
	UNITY_VERTEX_INPUT_INSTANCE_ID	//uint instanceID : SV_InstanceID;
};

struct VertexOutput {
	float4 clipPos : SV_POSITION;
	float3 normal : TEXCOORD0;
	float3 worldPos : TEXCOORD1;
	float3 vertexLighting : TEXCOORD2;
	float2 uv : TEXCOORD3;
#if defined(LIGHTMAP_ON)
	float2 lightmapUV : TEXCOORD4;
#endif
#if defined(DYNAMICLIGHTMAP_ON)
	float2 dynamicLightmapUV : TEXCOORD5;
#endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

//float3 SampleLightmap(float2 uv) {
//	return SampleSingleLightmap(
//		TEXTURE2D_PARAM(unity_Lightmap, samplerunity_Lightmap), uv
//	);
//}


float3 SampleLightmap(float2 uv) {
	return SampleSingleLightmap(
		TEXTURE2D_PARAM(unity_Lightmap, samplerunity_Lightmap), uv,
		float4(1, 1, 0, 0),
#if defined(UNITY_LIGHTMAP_FULL_HDR)
		false,
#else
		true,
#endif
		float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0, 0.0)
	);
}


float3 SampleDynamicLightmap(float2 uv) {
	return SampleSingleLightmap(
		TEXTURE2D_PARAM(unity_DynamicLightmap, samplerunity_DynamicLightmap), uv,
		float4(1, 1, 0, 0), false,
		float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0, 0.0)
	);
}

float3 BoxProjection(
	float3 direction, float3 position,
	float4 cubemapPosition, float4 boxMin, float4 boxMax
) {
	UNITY_BRANCH
		if (cubemapPosition.w > 0) {
			float3 factors =
				((direction > 0 ? boxMax.xyz : boxMin.xyz) - position) / direction;
			float scalar = min(min(factors.x, factors.y), factors.z);
			direction = direction * scalar + (position - cubemapPosition.xyz);
		}
	return direction;
}

//根据法线和观察向量求出反射向量，对环境的立方体贴图进行采样，求出环境颜色
float3 SampleEnvironment(LitSurface s) {
	//求出反射光线
	float3 reflectVector = reflect(-s.viewDir, s.normal);
	//根据粗糙程度求出mip下标
	float mip = PerceptualRoughnessToMipmapLevel(s.perceptualRoughness);

	//float3 uvw = reflectVector;
	float3 uvw = BoxProjection(
		reflectVector, s.position, unity_SpecCube0_ProbePosition,
		unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
	);
	float4 sample = SAMPLE_TEXTURECUBE_LOD(
		unity_SpecCube0, samplerunity_SpecCube0, uvw, mip
	);

	//float3 color = sample.rgb;

	float3 color = DecodeHDREnvironment(sample, unity_SpecCube0_HDR);

	//如果w < 1，表示一个点受到多个probe影响
	float blend = unity_SpecCube0_BoxMin.w;
	if (blend < 0.99999) {
		uvw = BoxProjection(
			reflectVector, s.position,
			unity_SpecCube1_ProbePosition,
			unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax
		);
		sample = SAMPLE_TEXTURECUBE_LOD(
			unity_SpecCube1, samplerunity_SpecCube0, uvw, mip
		);
		color = lerp(
			DecodeHDREnvironment(sample, unity_SpecCube1_HDR), color, blend
		);
	}

	return color;
}

float InsideCascadeCullingSphere(int index, float3 worldPos) {
	float4 s = _CascadeCullingSpheres[index];
	return dot(worldPos - s.xyz, worldPos - s.xyz) < s.w;
}

//float DistanceToCameraSqr(float3 worldPos) {
//	float3 cameraToFragment = worldPos - _WorldSpaceCameraPos;
//	return dot(cameraToFragment, cameraToFragment);
//}

float RealtimeToBakedShadowsInterpolator(float3 worldPos) {
	float d = distance(worldPos, _WorldSpaceCameraPos);
	return saturate(d * _GlobalShadowData.y + _GlobalShadowData.z);
}

float MixRealtimeAndBakedShadowAttenuation(float realtime, float4 bakedShadows, int lightIndex, float3 worldPos,
	bool isMainLight = false) {

	float t = RealtimeToBakedShadowsInterpolator(worldPos);
	//float fadedRealtime = lerp(realtime, 1, t);
	float fadedRealtime = saturate(realtime + t);
	float4 occlusionMask = _VisibleLightOcclusionMasks[lightIndex];
	float baked = dot(bakedShadows, occlusionMask);
	bool hasBakedShadows = occlusionMask.x >= 0.0;
	return fadedRealtime;
#if defined(_SHADOWMASK)
	//return fadedRealtime;
	
	if (hasBakedShadows) {
		return min(fadedRealtime, baked);
	}
#elif defined(_DISTANCE_SHADOWMASK)
	//return 0;

	if (hasBakedShadows) {
		bool bakedOnly = _VisibleLightSpotDirections[lightIndex].w > 0.0;
		if (!isMainLight &&bakedOnly) {
			return baked;
		}
		return lerp(realtime, baked, t);
	}
#elif defined(_SUBTRACTIVE_LIGHTING)
#if !defined(LIGHTMAP_ON)
	if (isMainLight) {
		return min(fadedRealtime, bakedShadows.x);
	}
#endif

#if !defined(_CASCADED_SHADOWS_HARD) && !defined(_CASCADED_SHADOWS_SOFT)
	if (lightIndex == 0) {
		return bakedShadows.x;
	}
#endif

#endif

	//return float4(1, 0, 0, 1);
	return fadedRealtime;
}

bool SkipRealtimeShadows(float3 worldPos) {
	return RealtimeToBakedShadowsInterpolator(worldPos) >= 1.0;
}



float HardShadowAttenuation(float4 shadowPos, bool cascade = false) {
	if (cascade) {
		return SAMPLE_TEXTURE2D_SHADOW(
			_CascadedShadowMap, sampler_CascadedShadowMap, shadowPos.xyz
		);
	}
	else {
		return SAMPLE_TEXTURE2D_SHADOW(
			_ShadowMap, sampler_ShadowMap, shadowPos.xyz
		);
	}
}

//float SoftShadowAttenuation(float4 shadowPos) {
//	real tentWeights[9];
//	real2 tentUVs[9];
//	SampleShadow_ComputeSamples_Tent_5x5(
//		_ShadowMapSize, shadowPos.xy, tentWeights, tentUVs
//	);
//	float attenuation = 0;
//	for (int i = 0; i < 9; i++) {
//		attenuation += tentWeights[i] * SAMPLE_TEXTURE2D_SHADOW(
//			_ShadowMap, sampler_ShadowMap, float3(tentUVs[i].xy, shadowPos.z)
//		);
//	}
//	return attenuation;
//}

float3 SampleLightProbes(LitSurface s) {
	//如果该物体是有LPPV，那么就采样LPPV，LPPV一般用在重要物体上，LPPV目前不支持移动平台
	if (unity_ProbeVolumeParams.x) {
		return SampleProbeVolumeSH4(
			TEXTURE3D_PARAM(unity_ProbeVolumeSH, samplerunity_ProbeVolumeSH),
			s.position, s.normal, unity_ProbeVolumeWorldToObject,
			unity_ProbeVolumeParams.y, unity_ProbeVolumeParams.z,
			unity_ProbeVolumeMin, unity_ProbeVolumeSizeInv
		);
	}
	else {//Light Probes一般用在小物件上
		float4 coefficients[7];
		coefficients[0] = unity_SHAr;
		coefficients[1] = unity_SHAg;
		coefficients[2] = unity_SHAb;
		coefficients[3] = unity_SHBr;
		coefficients[4] = unity_SHBg;
		coefficients[5] = unity_SHBb;
		coefficients[6] = unity_SHC;
		return max(0.0, SampleSH9(coefficients, s.normal));
	}
}

float SoftShadowAttenuation(float4 shadowPos, bool cascade = false) {
	real tentWeights[9];
	real2 tentUVs[9];
	float4 size = cascade ? _CascadedShadowMapSize : _ShadowMapSize;
	SampleShadow_ComputeSamples_Tent_5x5(
		size, shadowPos.xy, tentWeights, tentUVs
	);
	float attenuation = 0;
	for (int i = 0; i < 9; i++) {
		attenuation += tentWeights[i] * HardShadowAttenuation(
			float4(tentUVs[i].xy, shadowPos.z, 0), cascade
		);
	}
	return attenuation;
}

float ShadowAttenuation(int index, float3 worldPos) 
{
#if !defined(_RECEIVE_SHADOWS)
	return 1.0;
#elif !defined(_SHADOWS_HARD) && !defined(_SHADOWS_SOFT)
	return 1.0;
#endif

	if (_ShadowData[index].x <= 0 || SkipRealtimeShadows(worldPos)){
		//DistanceToCameraSqr(worldPos) > _GlobalShadowData.y) {//判断顶点到摄像机的距离如果大于阴影距离，则说明点不在阴影范围内
		return 1.0;
	}
	float4 shadowPos = mul(_WorldToShadowMatrices[index], float4(worldPos, 1.0));
	//阴影贴图需要的uv坐标不是裁剪空间坐标，而是NDC坐标，而且要转到[0,1]
	shadowPos.xyz /= shadowPos.w;
	shadowPos.xy = saturate(shadowPos.xy);
	shadowPos.xy = shadowPos.xy * _GlobalShadowData.x + _ShadowData[index].zw;


	float attenuation = 0;

#if defined(_SHADOWS_HARD)
#if defined(_SHADOWS_SOFT)
	if (_ShadowData[index].y == 0) {
		attenuation = HardShadowAttenuation(shadowPos);
	}
	else {
		attenuation = SoftShadowAttenuation(shadowPos);
	}
#else
	attenuation = HardShadowAttenuation(shadowPos);
#endif
#else
	attenuation = SoftShadowAttenuation(shadowPos);
#endif

	return lerp(1, attenuation, _ShadowData[index].x);
}


float CascadedShadowAttenuation(float3 worldPos, bool applyStrength = true) {
#if !defined(_RECEIVE_SHADOWS)
	return 1.0;
#elif !defined(_CASCADED_SHADOWS_HARD) && !defined(_CASCADED_SHADOWS_SOFT)
	return 1.0;
#endif

	//if (DistanceToCameraSqr(worldPos) > _GlobalShadowData.y) {
	if (SkipRealtimeShadows(worldPos)) {
		return 1.0;
	}

	float4 cascadeFlags = float4(
		InsideCascadeCullingSphere(0, worldPos),
		InsideCascadeCullingSphere(1, worldPos),
		InsideCascadeCullingSphere(2, worldPos),
		InsideCascadeCullingSphere(3, worldPos)
		);
	//return dot(cascadeFlags, 0.25);

	cascadeFlags.yzw = saturate(cascadeFlags.yzw - cascadeFlags.xyz);
	float cascadeIndex = 4 - dot(cascadeFlags, float4(4, 3, 2, 1));

	float4 shadowPos = mul(
		_WorldToShadowCascadeMatrices[cascadeIndex], float4(worldPos, 1.0)
	);
	float attenuation;
#if defined(_CASCADED_SHADOWS_HARD)
	attenuation = HardShadowAttenuation(shadowPos, true);
#else
	attenuation = SoftShadowAttenuation(shadowPos, true);
#endif

	if (applyStrength) {
		return lerp(1, attenuation, _CascadedShadowStrength);
	}
	else {
		return attenuation;
	}
}


//float3 MainLight(float3 normal, float3 worldPos) {
float3 MainLight(LitSurface s, float shadowAttenuation) {
	//float shadowAttenuation = CascadedShadowAttenuation(s.position);
	float3 lightColor = _VisibleLightColors[0].rgb;
	float3 lightDirection = _VisibleLightDirectionsOrPositions[0].xyz;
	//float diffuse = saturate(dot(normal, lightDirection));
	float3 color = LightSurface(s, lightDirection);
	color *= shadowAttenuation;
	return color * lightColor;
}

//float3 DiffuseLight(int index, float3 normal, float3 worldPos, float shadowAttenuation) {
float3 GenericLight(int index, LitSurface s, float shadowAttenuation) {
	float3 lightColor = _VisibleLightColors[index].rgb;
	float4 lightPositionOrDirection = _VisibleLightDirectionsOrPositions[index];
	float4 lightAttenuation = _VisibleLightAttenuations[index];
	float3 spotDirection = _VisibleLightSpotDirections[index].xyz;
	/*float3 lightVector = lightPositionOrDirection.xyz - worldPos * lightPositionOrDirection.w;
	float3 lightDirection = normalize(lightVector);	*/
	float3 lightVector =
		lightPositionOrDirection.xyz - s.position * lightPositionOrDirection.w;
	float3 lightDirection = normalize(lightVector);
	//float diffuse = saturate(dot(normal, lightDirection));
	float3 color = LightSurface(s, lightDirection);
	float rangeFade = dot(lightVector, lightVector) * lightAttenuation.x;
	rangeFade = saturate(1.0 - rangeFade * rangeFade);
	rangeFade *= rangeFade;

	float spotFade = dot(spotDirection, lightDirection);
	spotFade = saturate(spotFade * lightAttenuation.z + lightAttenuation.w);
	spotFade *= spotFade;

	float distanceSqr = max(dot(lightVector, lightVector), 0.00001);
	color *= shadowAttenuation * spotFade * rangeFade / distanceSqr;
	return color * lightColor;
}

float3 SubtractiveLighting(LitSurface s, float3 bakedLighting) {
	float3 lightColor = _VisibleLightColors[0].rgb;
	float3 lightDirection = _VisibleLightDirectionsOrPositions[0].xyz;
	float3 diffuse = lightColor * saturate(dot(lightDirection, s.normal));
	float shadowAttenuation = saturate(
		CascadedShadowAttenuation(s.position, false) +
		RealtimeToBakedShadowsInterpolator(s.position)
	);
	float3 shadowedLightingGuess = diffuse * (1.0 - shadowAttenuation);
	float3 subtractedLighting = bakedLighting - shadowedLightingGuess;
	subtractedLighting = max(subtractedLighting, _SubtractiveShadowColor);
	subtractedLighting =
		lerp(bakedLighting, subtractedLighting, _CascadedShadowStrength);
	return min(bakedLighting, subtractedLighting);
}

float3 GlobalIllumination(VertexOutput input, LitSurface surface) {
	//return SampleLightProbes(surface);
	float3 gi = 0;
#if defined(LIGHTMAP_ON)
	gi = SampleLightmap(input.lightmapUV);

#if defined(_SUBTRACTIVE_LIGHTING)
	gi = SubtractiveLighting(surface, gi);
#endif

#if defined(DYNAMICLIGHTMAP_ON)
	gi += SampleDynamicLightmap(input.dynamicLightmapUV);
	//return float3(0, 1, 0);

#endif
	return gi;
#elif defined(DYNAMICLIGHTMAP_ON)//动态贴图开启，是通过Lighting Settings里Realtime Lighting-Realtime Global Illumination选中开启的，是对于静态物体而言
	//return float3(0, 1, 1);
	return SampleDynamicLightmap(input.dynamicLightmapUV);
#else
	//return float3(0, 0, 1);

		//Unity会把光照信息烘焙到LightProbes，动态物体是通过采集LightProbes获取周围间接光颜色，如果静态物体通过此方法获取，会是黑色
	return SampleLightProbes(surface);
#endif
}

float4 BakedShadows(VertexOutput input, LitSurface surface) {
#if defined(LIGHTMAP_ON)
#if defined(_SHADOWMASK) || defined(_DISTANCE_SHADOWMASK)
	//return float4(1, 0, 0, 1);
	return SAMPLE_TEXTURE2D(
		unity_ShadowMask, samplerunity_ShadowMask, input.lightmapUV
	);
#endif
#elif defined(_SHADOWMASK) || defined(_DISTANCE_SHADOWMASK)|| \
		defined(_SUBTRACTIVE_LIGHTING)
	//return float4(0, 1, 0, 1);
	if (unity_ProbeVolumeParams.x) {
		return SampleProbeOcclusion(
			TEXTURE3D_PARAM(unity_ProbeVolumeSH, samplerunity_ProbeVolumeSH),
			surface.position, unity_ProbeVolumeWorldToObject,
			unity_ProbeVolumeParams.y, unity_ProbeVolumeParams.z,
			unity_ProbeVolumeMin, unity_ProbeVolumeSizeInv
		);
	}
	return unity_ProbesOcclusion;
#endif
	//return float4(0, 0, 1, 1);

	return 1.0;
}

VertexOutput LitPassVertex(VertexInput input) {
	VertexOutput output;

	//计算unity_InstanceID
	UNITY_SETUP_INSTANCE_ID(input);

	//把input里的instanceID赋值给output.instanceID
	UNITY_TRANSFER_INSTANCE_ID(input, output);

	//以unity_InstanceID为下标从数组里取M 矩阵
	float4 worldPos = mul(UNITY_MATRIX_M, float4(input.pos.xyz, 1.0));
	output.clipPos = mul(unity_MatrixVP, worldPos);
	//output.normal = mul((float3x3)UNITY_MATRIX_M, input.normal);

#if defined(UNITY_ASSUME_UNIFORM_SCALING)
	output.normal = mul((float3x3)UNITY_MATRIX_M, input.normal);
#else
	output.normal = normalize(mul(input.normal, (float3x3)UNITY_MATRIX_I_M));
#endif

	//output.normal = mul((float3x3)UNITY_MATRIX_M, input.normal);

	output.worldPos = worldPos.xyz;

	LitSurface surface = GetLitSurfaceVertex(output.normal, output.worldPos);
	output.vertexLighting = 0;
	for (int i = 4; i < min(unity_LightIndicesOffsetAndCount.y, 8); i++) {
		int lightIndex = unity_4LightIndices1[i - 4];
		//output.vertexLighting +=
		//	DiffuseLight(lightIndex, output.normal, output.worldPos, 1);
		output.vertexLighting += GenericLight(lightIndex, surface, 1);
	}
	output.uv = TRANSFORM_TEX(input.uv, _MainTex);
#if defined(LIGHTMAP_ON)
	output.lightmapUV =
		input.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
#endif

#if defined(DYNAMICLIGHTMAP_ON)
	output.dynamicLightmapUV =
		input.dynamicLightmapUV * unity_DynamicLightmapST.xy +
		unity_DynamicLightmapST.zw;
#endif

	return output;
}

void LODCrossFadeClip(float4 clipPos) 
{
	//float lodClipBias = (clipPos.y % 64) / 64;
	////if (unity_LODFade.x < 0.5) {
	////	lodClipBias = 1.0 - lodClipBias;
	////}
	//clip(unity_LODFade.x - lodClipBias);

	//直接用裁剪空间的xy，因为图片是repeat
	float2 ditherUV = TRANSFORM_TEX(clipPos.xy, _DitherTexture);
	float lodClipBias = SAMPLE_TEXTURE2D(_DitherTexture, sampler_DitherTexture, ditherUV).a;
	if (unity_LODFade.x < 0.5) {
		lodClipBias = 1.0 - lodClipBias;
	}
	clip(unity_LODFade.x - lodClipBias);
}

float4 LitPassFragment(VertexOutput input, FRONT_FACE_TYPE isFrontFace : FRONT_FACE_SEMANTIC) : SV_TARGET{

	//计算unity_InstanceID
	UNITY_SETUP_INSTANCE_ID(input);
	input.normal = normalize(input.normal);
	//#define IS_FRONT_VFACE(VAL, FRONT, BACK) ((VAL) ? (FRONT) : (BACK))
	input.normal = IS_FRONT_VFACE(isFrontFace, input.normal, -input.normal);

#if defined(LOD_FADE_CROSSFADE)
	//return float4(1, 0, 0, 0);
	LODCrossFadeClip(input.clipPos);
#endif

	//取数组PerInstance里_Color属性
	//float3 albedo = UNITY_ACCESS_INSTANCED_PROP(PerInstance, _Color).rgb;

	float4 albedoAlpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
	albedoAlpha *= UNITY_ACCESS_INSTANCED_PROP(PerInstance, _Color);

#if defined(_CLIPPING_ON)
	clip(albedoAlpha.a - _Cutoff);
#endif

	int i = 0;
	int lightIndex = 0;

	float3 viewDir = normalize(_WorldSpaceCameraPos - input.worldPos.xyz);
	LitSurface surface = GetLitSurface(
		input.normal, input.worldPos, viewDir,
		albedoAlpha.rgb,
		UNITY_ACCESS_INSTANCED_PROP(PerInstance, _Metallic),
		UNITY_ACCESS_INSTANCED_PROP(PerInstance, _Smoothness)
	);

#if defined(_PREMULTIPLY_ALPHA)
	PremultiplyAlpha(surface, albedoAlpha.a);
#endif

	float4 bakedShadows = BakedShadows(input, surface);

	//float3 diffuseLight = input.vertexLighting;
	float3 color = input.vertexLighting * surface.diffuse;
#if defined(_CASCADED_SHADOWS_HARD) || defined(_CASCADED_SHADOWS_SOFT)
	//diffuseLight += MainLight(input.normal, input.worldPos);
	#if !(defined(LIGHTMAP_ON) && defined(_SUBTRACTIVE_LIGHTING))
		float shadowAttenuation = MixRealtimeAndBakedShadowAttenuation(
			CascadedShadowAttenuation(surface.position), bakedShadows, 0, surface.position, true
		);
		//有阴影才会对主灯光颜色采样
		color += MainLight(surface, shadowAttenuation);
	#endif
#endif

	for (i = 0; i < min(unity_LightIndicesOffsetAndCount.y, 4); i++) {
		lightIndex = unity_4LightIndices0[i];
		//float shadowAttenuation = ShadowAttenuation(lightIndex, input.worldPos);
		float shadowAttenuation = MixRealtimeAndBakedShadowAttenuation(
			ShadowAttenuation(lightIndex, surface.position), bakedShadows, 
			lightIndex,	surface.position
		);
		color += GenericLight(lightIndex, surface, shadowAttenuation);
	}

	//for (i = 4; i < min(unity_LightIndicesOffsetAndCount.y, 8); i++) {
	//	lightIndex = unity_4LightIndices1[i - 4];
	//	diffuseLight +=
	//		DiffuseLight(lightIndex, input.normal, input.worldPos);
	//}

	//float3 color = diffuseLight * albedoAlpha.rgb;
	//return float4(color, albedoAlpha.a); 

	color += ReflectEnvironment(surface, SampleEnvironment(surface));
	color += GlobalIllumination(input, surface) * surface.diffuse;
	color += UNITY_ACCESS_INSTANCED_PROP(PerInstance, _EmissionColor).rgb;

	//color = UNITY_ACCESS_INSTANCED_PROP(PerInstance, _EmissionColor).rgb;

	//color = albedoAlpha;
	//color = BakedShadows(input, surface);
	//float temp = MixRealtimeAndBakedShadowAttenuation(
	//	CascadedShadowAttenuation(surface.position), bakedShadows, 0, surface.position
	//);
	//color = temp;
	///*color = float3(bakedShadows.x, 0,0);
	//color = bakedShadows;*/
	//color = MainLight(surface, temp);
	//color = GlobalIllumination(input, surface) * surface.diffuse;
	return float4(color, albedoAlpha.a);

	/*float3 color = diffuseLight * albedo.rgb;
	return float4(color, 1);*/
}



#endif // MYRP_LIT_INCLUDED
