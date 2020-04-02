struct VertexOutputForwardBase
{
	UNITY_POSITION(pos);
	float4 tex                            : TEXCOORD0;
	float4 eyeVec                         : TEXCOORD1;    // eyeVec.xyz | fogCoord
	float4 tangentToWorldAndPackedData[3] : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
	half4 ambientOrLightmapUV             : TEXCOORD5;    // SH or Lightmap UV
	UNITY_LIGHTING_COORDS(6, 7)

		// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
#if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
		float3 posWorld                     : TEXCOORD8;
#endif

	UNITY_VERTEX_INPUT_INSTANCE_ID
		UNITY_VERTEX_OUTPUT_STEREO
};


float SmoothnessToPerceptualRoughness(float smoothness)
{
	return (1 - smoothness);
}

half3 BRDF3_Direct(half3 diffColor, half3 specColor, half rlPow4, half smoothness)
{
	half LUT_RANGE = 16.0; // must match range in NHxRoughness() function in GeneratedTextures.cpp
	// Lookup texture to save instructions
	half specular = tex2D(unity_NHxRoughness, half2(rlPow4, SmoothnessToPerceptualRoughness(smoothness))).r * LUT_RANGE;
#if defined(_SPECULARHIGHLIGHTS_OFF)
	specular = 0.0;
#endif

	return diffColor + specular * specColor;
}

// Old school, not microfacet based Modified Normalized Blinn-Phong BRDF
// Implementation uses Lookup texture for performance
//
// * Normalized BlinnPhong in RDF form
// * Implicit Visibility term
// * No Fresnel term
//
// TODO: specular is too weak in Linear rendering mode
half4 BRDF3_Unity_PBS(half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
	float3 normal, float3 viewDir,
	UnityLight light, UnityIndirect gi)
{
	float3 reflDir = reflect(viewDir, normal);

	half nl = saturate(dot(normal, light.dir));
	half nv = saturate(dot(normal, viewDir));

	// Vectorize Pow4 to save instructions
	half2 rlPow4AndFresnelTerm = Pow4(float2(dot(reflDir, light.dir), 1 - nv));  // use R.L instead of N.H to save couple of instructions
	half rlPow4 = rlPow4AndFresnelTerm.x; // power exponent must match kHorizontalWarpExp in NHxRoughness() function in GeneratedTextures.cpp
	half fresnelTerm = rlPow4AndFresnelTerm.y;

	half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));

	half3 color = BRDF3_Direct(diffColor, specColor, rlPow4, smoothness);
	color *= light.color * nl;
	color += BRDF3_Indirect(diffColor, specColor, gi, grazingTerm, fresnelTerm);

	return half4(color, 1);
}

half4 fragForwardBaseInternal(VertexOutputForwardBase i)
{
	UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

	//#define FRAGMENT_SETUP(x) FragmentCommonData x = \
    //FragmentSetup(i.tex, i.eyeVec.xyz, IN_VIEWDIR4PARALLAX(i), i.tangentToWorldAndPackedData, IN_WORLDPOS(i));
	//i.tex是uv
	FRAGMENT_SETUP(s)

		UNITY_SETUP_INSTANCE_ID(i);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

	UnityLight mainLight = MainLight();
	UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);

	half occlusion = Occlusion(i.tex.xy);
	UnityGI gi = FragmentGI(s, occlusion, i.ambientOrLightmapUV, atten, mainLight);

	half4 c = UNITY_BRDF_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
	c.rgb += Emission(i.tex.xy);

	UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
	UNITY_APPLY_FOG(_unity_fogCoord, c.rgb);
	return OutputForward(c, s.alpha);
}

// Same as ParallaxOffset in Unity CG, except:
//  *) precision - half instead of float
half2 ParallaxOffset1Step(half h, half height, half3 viewDir)
{
	h = h * height - height / 2.0;
	half3 v = normalize(viewDir);
	v.z += 0.42;
	return h * (v.xy / v.z);
}

float4 Parallax(float4 texcoords, half3 viewDir)
{
#if !defined(_PARALLAXMAP) || (SHADER_TARGET < 30)
	// Disable parallax on pre-SM3.0 shader target models
	return texcoords;
#else
	half h = tex2D(_ParallaxMap, texcoords.xy).g;
	float2 offset = ParallaxOffset1Step(h, _Parallax, viewDir);
	return float4(texcoords.xy + offset, texcoords.zw + offset);
#endif

}

half4 SpecularGloss(float2 uv)
{
	half4 sg;
#ifdef _SPECGLOSSMAP
#if defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A)
	sg.rgb = tex2D(_SpecGlossMap, uv).rgb;
	sg.a = tex2D(_MainTex, uv).a;
#else
	sg = tex2D(_SpecGlossMap, uv);
#endif
	sg.a *= _GlossMapScale;
#else
	sg.rgb = _SpecColor.rgb;
#ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
	sg.a = tex2D(_MainTex, uv).a * _GlossMapScale;
#else
	sg.a = _Glossiness;
#endif
#endif
	return sg;
}



half SpecularStrength(half3 specular)
{
#if (SHADER_TARGET < 30)
	// SM2.0: instruction count limitation
	// SM2.0: simplified SpecularStrength
	return specular.r; // Red channel - because most metals are either monocrhome or with redish/yellowish tint
#else
	return max(max(specular.r, specular.g), specular.b);
#endif
}

// Diffuse/Spec Energy conservation
inline half3 EnergyConservationBetweenDiffuseAndSpecular(half3 albedo, half3 specColor, out half oneMinusReflectivity)
{
	oneMinusReflectivity = 1 - SpecularStrength(specColor);
#if !UNITY_CONSERVE_ENERGY
	return albedo;
#elif UNITY_CONSERVE_ENERGY_MONOCHROME
	return albedo * oneMinusReflectivity;
#else
	return albedo * (half3(1, 1, 1) - specColor);
#endif
}

inline FragmentCommonData SpecularSetup(float4 i_tex)
{
	half4 specGloss = SpecularGloss(i_tex.xy);
	half3 specColor = specGloss.rgb;
	half smoothness = specGloss.a;

	half oneMinusReflectivity;
	half3 diffColor = EnergyConservationBetweenDiffuseAndSpecular(Albedo(i_tex), specColor, /*out*/ oneMinusReflectivity);

	FragmentCommonData o = (FragmentCommonData)0;
	o.diffColor = diffColor;
	o.specColor = specColor;
	o.oneMinusReflectivity = oneMinusReflectivity;
	o.smoothness = smoothness;
	return o;
}

//FragmentSetup(i.tex, i.eyeVec.xyz, IN_VIEWDIR4PARALLAX(i), i.tangentToWorldAndPackedData, IN_WORLDPOS(i));
// parallax transformed texcoord is used to sample occlusion
inline FragmentCommonData FragmentSetup(inout float4 i_tex, float3 i_eyeVec, half3 i_viewDirForParallax, float4 tangentToWorld[3], float3 i_posWorld)
{
	i_tex = Parallax(i_tex, i_viewDirForParallax);

	half alpha = Alpha(i_tex.xy);
#if defined(_ALPHATEST_ON)
	clip(alpha - _Cutoff);
#endif

	FragmentCommonData o = UNITY_SETUP_BRDF_INPUT(i_tex);
	o.normalWorld = PerPixelWorldNormal(i_tex, tangentToWorld);
	o.eyeVec = NormalizePerPixelNormal(i_eyeVec);
	o.posWorld = i_posWorld;

	// NOTE: shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
	o.diffColor = PreMultiplyAlpha(o.diffColor, alpha, o.oneMinusReflectivity, /*out*/ o.alpha);
	return o;
}

