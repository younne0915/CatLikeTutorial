#ifndef MYRP_LIGHTING_INCLUDED
#define MYRP_LIGHTING_INCLUDED

struct LitSurface {
	float3 normal, position, viewDir;
	float3 diffuse, specular;
	float roughness;
};

#endif // MYRP_LIGHTING_INCLUDED