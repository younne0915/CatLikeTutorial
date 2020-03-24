using System.Collections.Generic;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Callbacks;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Rendering;

public class MyPipelineShaderPreprocessor : IPreprocessShaders
{
    public int callbackOrder
    {
        get
        {
            return 0;
        }
    }

    MyPipelineAsset pipelineAsset;

    int shaderVariantCount, strippedCount;

    bool stripCascadedShadows, stripLODCrossFading;

    static MyPipelineShaderPreprocessor instance;
    static ShaderKeyword cascadedShadowsHardKeyword =
        new ShaderKeyword("_CASCADED_SHADOWS_HARD");
    static ShaderKeyword cascadedShadowsSoftKeyword =
        new ShaderKeyword("_CASCADED_SHADOWS_SOFT");
    static ShaderKeyword lodCrossFadeKeyword =
        new ShaderKeyword("LOD_FADE_CROSSFADE");

    bool Strip(ShaderCompilerData data)
    {
        return
            stripCascadedShadows && (
                data.shaderKeywordSet.IsEnabled(cascadedShadowsHardKeyword) ||
                data.shaderKeywordSet.IsEnabled(cascadedShadowsSoftKeyword) ||
            stripLODCrossFading &&
            data.shaderKeywordSet.IsEnabled(lodCrossFadeKeyword));
    }

    public MyPipelineShaderPreprocessor()
    {
        instance = this;
        pipelineAsset = GraphicsSettings.renderPipelineAsset as MyPipelineAsset;
        if (pipelineAsset == null)
        {
            return;
        }
        stripCascadedShadows = !pipelineAsset.HasShadowCascades;
        stripLODCrossFading = !pipelineAsset.HasLODCrossFading;
    }

    public void OnProcessShader(
        Shader shader, ShaderSnippetData snippet, IList<ShaderCompilerData> data
    )
    {
        if (pipelineAsset == null)
        {
            return;
        }
        shaderVariantCount += data.Count;

        for (int i = 0; i < data.Count; i++)
        {
            if (Strip(data[i]))
            {
                data.RemoveAt(i--);
                strippedCount += 1;
            }
        }
    }

    [PostProcessBuild(0)]
    static void LogVariantCount(BuildTarget target, string path)
    {
        instance.LogVariantCount();
        instance = null;
    }

    void LogVariantCount()
    {
        if (pipelineAsset == null)
        {
            return;
        }

        int finalCount = shaderVariantCount - strippedCount;
        int percentage =
            Mathf.RoundToInt(100f * finalCount / shaderVariantCount);
        Debug.Log(
            "Included " + finalCount + " shader variants out of " +
            shaderVariantCount + " (" + percentage + "%)."
        );
    }
}