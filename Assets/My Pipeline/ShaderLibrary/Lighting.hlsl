﻿#ifndef MYRP_LIGHTING_INCLUDED
#define MYRP_LIGHTING_INCLUDED

TEXTURECUBE(unity_SpecCube0);
SAMPLER(samplerunity_SpecCube0);

struct LitSurface {
	float3 normal, position, viewDir;
	float3 diffuse, specular;
	float perceptualRoughness, roughness;
	bool perfectDiffuser;
};

float3 ReflectEnvironment(LitSurface s, float3 environment) {
	if (s.perfectDiffuser) {
		return 0;
	}

	environment *= s.specular;
	environment /= s.roughness * s.roughness + 1.0;
	return environment;
}

LitSurface GetLitSurface(
	float3 normal, float3 position, float3 viewDir,
	float3 color, float smoothness, bool perfectDiffuser = false
) {
	LitSurface s;
	s.normal = normal;
	s.position = position;
	s.viewDir = viewDir;
	s.diffuse = color;
	if (perfectDiffuser) {
		smoothness = 0.0;
		s.specular = 0.0;
	}
	else {
		s.specular = 0.04;
		s.diffuse *= 1.0 - 0.04;
	}
	s.perfectDiffuser = perfectDiffuser;
	s.perceptualRoughness = 1.0 - smoothness;
	s.roughness = s.perceptualRoughness * s.perceptualRoughness;
	return s;
}

float3 LightSurface(LitSurface s, float3 lightDir) {
	float3 color = s.diffuse;
	if (!s.perfectDiffuser) 
	{
		float3 halfDir = SafeNormalize(lightDir + s.viewDir);
		float nh = saturate(dot(s.normal, halfDir));
		float lh = saturate(dot(lightDir, halfDir));
		float d = nh * nh * (s.roughness * s.roughness - 1.0) + 1.00001;
		float normalizationTerm = s.roughness * 4.0 + 2.0;
		float specularTerm = s.roughness * s.roughness;
		specularTerm /= (d * d) * max(0.1, lh * lh) * normalizationTerm;
		color += specularTerm * s.specular;
	}
	return color * saturate(dot(s.normal, lightDir));
}

LitSurface GetLitSurfaceVertex(float3 normal, float3 position) {
	return GetLitSurface(normal, position, 0, 1, 0, true);
}

#endif // MYRP_LIGHTING_INCLUDED