using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

[CreateAssetMenu(menuName ="Rendering/My Pipeline")]
public class MyPipelineAsset : RenderPipelineAsset
{

    public enum MSAAMode
    {
        Off = 1,
        _2x = 2,
        _4x = 4,
        _8x = 8
    }


    public enum ShadowMapSize
    {
        _256 = 256,
        _512 = 512,
        _1024 = 1024,
        _2048 = 2048,
        _4096 = 4096
    }

    public enum ShadowCascades
    {
        Zero = 0,
        Two = 2,
        Four = 4
    }

    [SerializeField]
    bool dynamicBatching;

    [SerializeField]
    bool instancing;

    [SerializeField]
    ShadowMapSize shadowMapSize = ShadowMapSize._1024;

    [SerializeField]
    float shadowDistance = 100f;


    [SerializeField, HideInInspector]
    float twoCascadesSplit = 0.25f;

    [SerializeField, HideInInspector]
    Vector3 fourCascadesSplit = new Vector3(0.067f, 0.2f, 0.467f);

    [SerializeField, Range(0.01f, 2f)]
    float shadowFadeRange = 1f;

    [SerializeField]
    Texture2D ditherTexture = null;

    [SerializeField, Range(0f, 120f)]
    float ditherAnimationSpeed = 30f;

    [SerializeField]
    bool supportLODCrossFading = true;

    [SerializeField]
    MyPostProcessingStack defaultStack;

    [SerializeField, Range(0.25f, 2f)]
    float renderScale = 1f;

    [SerializeField]
    MSAAMode MSAA = MSAAMode.Off;

    [SerializeField]
    bool allowHDR;

    public bool HasShadowCascades
    {
        get
        {
            return shadowCascades != ShadowCascades.Zero;
        }
    }

    public bool HasLODCrossFading
    {
        get
        {
            return supportLODCrossFading;
        }
    }

    [SerializeField]
    ShadowCascades shadowCascades = ShadowCascades.Four;

    /// <summary>
    /// 每次改变MyPipelineAsset的值，InternalCreatePipeline就会被调用
    /// 当动态batch和GPU instancing都可用的时候，Unity优先使用GPU instancing
    /// </summary>
    /// <returns></returns>
    protected override IRenderPipeline InternalCreatePipeline()
    {
        //Debug.LogErrorFormat("InternalCreatePipeline dynamicBatching = {0}", dynamicBatching);
        Vector3 shadowCascadeSplit = shadowCascades == ShadowCascades.Four ?
            fourCascadesSplit : new Vector3(twoCascadesSplit, 0f);
        return new MyPipeline(
            dynamicBatching, instancing, defaultStack,
            ditherTexture, ditherAnimationSpeed,
            (int)shadowMapSize,
            shadowDistance, shadowFadeRange,
            (int)shadowCascades, shadowCascadeSplit,
            renderScale, (int)MSAA, allowHDR
            );
    }
}
