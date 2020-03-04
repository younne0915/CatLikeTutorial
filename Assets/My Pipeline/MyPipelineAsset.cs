using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

[CreateAssetMenu(menuName ="Rendering/My Pipeline")]
public class MyPipelineAsset : RenderPipelineAsset
{
    [SerializeField]
    bool dynamicBatching;

    [SerializeField]
    bool instancing;

    public enum ShadowMapSize
    {
        _256 = 256,
        _512 = 512,
        _1024 = 1024,
        _2048 = 2048,
        _4096 = 4096
    }

    [SerializeField]
    ShadowMapSize shadowMapSize = ShadowMapSize._1024;

    /// <summary>
    /// 每次改变MyPipelineAsset的值，InternalCreatePipeline就会被调用
    /// 当动态batch和GPU instancing都可用的时候，Unity优先使用GPU instancing
    /// </summary>
    /// <returns></returns>
    protected override IRenderPipeline InternalCreatePipeline()
    {
        //Debug.LogErrorFormat("InternalCreatePipeline dynamicBatching = {0}", dynamicBatching);
        return new MyPipeline(dynamicBatching, instancing, (int)shadowMapSize);
    }
}
