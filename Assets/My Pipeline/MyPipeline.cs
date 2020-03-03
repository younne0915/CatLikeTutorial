using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using Conditional = System.Diagnostics.ConditionalAttribute;

public class MyPipeline : RenderPipeline
{
    private CullResults cull;

    DrawRendererFlags drawFlags;

    const int maxVisibleLights = 16;

    static int visibleLightColorsId = Shader.PropertyToID("_VisibleLightColors");
    static int visibleLightDirectionsOrPositionsId = Shader.PropertyToID("_VisibleLightDirectionsOrPositions");
    static int visibleLightAttenuationsId = Shader.PropertyToID("_VisibleLightAttenuations");
    static int visibleLightSpotDirectionsId = Shader.PropertyToID("_VisibleLightSpotDirections");
    static int lightIndicesOffsetAndCountID = Shader.PropertyToID("unity_LightIndicesOffsetAndCount");

    Vector4[] visibleLightColors = new Vector4[maxVisibleLights];
    Vector4[] visibleLightDirectionsOrPositions = new Vector4[maxVisibleLights];
    Vector4[] visibleLightAttenuations = new Vector4[maxVisibleLights];
    Vector4[] visibleLightSpotDirections = new Vector4[maxVisibleLights];

    RenderTexture shadowMap;

    CommandBuffer cameraBuffer = new CommandBuffer
    {
        name = "Render Camera2"
    };

    CommandBuffer shadowBuffer = new CommandBuffer
    {
        name = "Render Shadows"
    };

    Material errorMaterial;

    public MyPipeline(bool dynamicBatching, bool instancing)
    {
        GraphicsSettings.lightsUseLinearIntensity = true;

        if (dynamicBatching)
        {
            drawFlags = DrawRendererFlags.EnableDynamicBatching;
        }
        if (instancing)
        {
            drawFlags |= DrawRendererFlags.EnableInstancing;
        }
    }

    void RenderShadows(ScriptableRenderContext context)
    {
        shadowMap = RenderTexture.GetTemporary(
            512, 512, 16, RenderTextureFormat.Shadowmap
        );
        shadowMap.filterMode = FilterMode.Bilinear;
        shadowMap.wrapMode = TextureWrapMode.Clamp;

        CoreUtils.SetRenderTarget(shadowBuffer, shadowMap, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, ClearFlag.Depth);
        shadowBuffer.BeginSample("Render Shadows");
        context.ExecuteCommandBuffer(shadowBuffer);
        shadowBuffer.Clear();

        Matrix4x4 viewMatrix, projectionMatrix;
        ShadowSplitData splitData;
        cull.ComputeSpotShadowMatricesAndCullingPrimitives(
            0, out viewMatrix, out projectionMatrix, out splitData
        );

        shadowBuffer.SetViewProjectionMatrices(viewMatrix, projectionMatrix);
        context.ExecuteCommandBuffer(shadowBuffer);
        shadowBuffer.Clear();

        var shadowSettings = new DrawShadowsSettings(cull, 0);
        context.DrawShadows(ref shadowSettings);

        shadowBuffer.EndSample("Render Shadows");
        context.ExecuteCommandBuffer(shadowBuffer);
        shadowBuffer.Clear();
    }

    public override void Render(ScriptableRenderContext renderContext, Camera[] cameras)
    {
        base.Render(renderContext, cameras);

        foreach (var camera in cameras)
        {
            Render(renderContext, camera);
        }
    }

    void Render(ScriptableRenderContext context, Camera camera)
    {
        ScriptableCullingParameters cullingParameters;
        if (!CullResults.GetCullingParameters(camera, out cullingParameters))
        {
            return;
        }

#if UNITY_EDITOR
        if (camera.cameraType == CameraType.SceneView)
        {
            ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
        }
#endif

        RenderShadows(context);

        CullResults.Cull(ref cullingParameters, context, ref cull);

        context.SetupCameraProperties(camera);

        CameraClearFlags clearFlags = camera.clearFlags;


        cameraBuffer.ClearRenderTarget(
                                (clearFlags & CameraClearFlags.Depth) != 0,
                                (clearFlags & CameraClearFlags.Color) != 0,
                                camera.backgroundColor
                                );

        if (cull.visibleLights.Count > 0)
        {
            ConfigureLights();
        }
        else
        {
            cameraBuffer.SetGlobalVector( lightIndicesOffsetAndCountID, Vector4.zero );
        }

        //cameraBuffer.BeginSample("Render Camera33");

        cameraBuffer.SetGlobalVectorArray(
            visibleLightColorsId, visibleLightColors
        );
        cameraBuffer.SetGlobalVectorArray(
            visibleLightDirectionsOrPositionsId, visibleLightDirectionsOrPositions
        );
        cameraBuffer.SetGlobalVectorArray(
            visibleLightAttenuationsId, visibleLightAttenuations
        );

        cameraBuffer.SetGlobalVectorArray(
            visibleLightSpotDirectionsId, visibleLightSpotDirections
        );

        context.ExecuteCommandBuffer(cameraBuffer);
        cameraBuffer.Clear();

        var drawSettings = new DrawRendererSettings(camera, new ShaderPassName("SRPDefaultUnlit"))
        {
            flags = drawFlags//,
            //rendererConfiguration = RendererConfiguration.PerObjectLightIndices8
        };

        if (cull.visibleLights.Count > 0)
        {
            drawSettings.rendererConfiguration =
                RendererConfiguration.PerObjectLightIndices8;
        }

        drawSettings.sorting.flags = SortFlags.CommonOpaque;

        var filterSettings = new FilterRenderersSettings(true)
        {
            renderQueueRange = RenderQueueRange.opaque
        };

        context.DrawRenderers(
            cull.visibleRenderers, ref drawSettings, filterSettings
        );

        context.DrawSkybox(camera);

        drawSettings.sorting.flags = SortFlags.CommonTransparent;
        filterSettings.renderQueueRange = RenderQueueRange.transparent;
        context.DrawRenderers(
            cull.visibleRenderers, ref drawSettings, filterSettings
        );

        DrawDefaultPipeline(context, camera);

        //cameraBuffer.EndSample("Render Camera33");

        context.ExecuteCommandBuffer(cameraBuffer);
        cameraBuffer.Clear();

        context.Submit();

        if (shadowMap)
        {
            RenderTexture.ReleaseTemporary(shadowMap);
            shadowMap = null;
        }
    }

    void ConfigureLights()
    {
        //int i = 0;
        for (int i = 0; i < cull.visibleLights.Count; i++)
        {
            if (i == maxVisibleLights)
            {
                break;
            }

            VisibleLight light = cull.visibleLights[i];
            visibleLightColors[i] = light.finalColor;

            Vector4 attenuation = Vector4.zero;
            attenuation.w = 1f;

            if (light.lightType == LightType.Directional)
            {
                //因为要求出光源的朝向，相当于要知道光源transform.forward,矩阵第三列是光源z轴在世界坐标系下表示，也就是forward
                Vector4 v = light.localToWorld.GetColumn(2);
                v.x = -v.x;
                v.y = -v.y;
                v.z = -v.z;
                visibleLightDirectionsOrPositions[i] = v;
            }
            else
            {
                //第四列是光源原点在世界坐标系中的位置
                visibleLightDirectionsOrPositions[i] = light.localToWorld.GetColumn(3);
                attenuation.x = 1f / Mathf.Max(light.range * light.range, 0.00001f);

                if (light.lightType == LightType.Spot)
                {
                    Vector4 v = light.localToWorld.GetColumn(2);
                    v.x = -v.x;
                    v.y = -v.y;
                    v.z = -v.z;
                    //存储spot光源方向
                    visibleLightSpotDirections[i] = v;

                    float outerRad = Mathf.Deg2Rad * 0.5f * light.spotAngle;
                    float outerCos = Mathf.Cos(outerRad);
                    float outerTan = Mathf.Tan(outerRad);
                    float innerCos = Mathf.Cos(Mathf.Atan(((46f / 64f) * outerTan)));
                    float angleRange = Mathf.Max(innerCos - outerCos, 0.001f);
                    attenuation.z = 1f / angleRange;
                    attenuation.w = -outerCos * attenuation.z;
                }
            }
            visibleLightAttenuations[i] = attenuation;
        }

        //如果超过maxVisibleLights数量的灯光，该脚本不会传输给Shader
        //但是Unity自身可能会对超出maxVisibleLights的灯光，进行unity_4LightIndices0赋值，下标会找不到，_VisibleLightColors越界
        if (cull.visibleLights.Count > maxVisibleLights)
        {
            int[] lightIndices = cull.GetLightIndexMap();
            for (int i = maxVisibleLights; i < cull.visibleLights.Count; i++)
            {
                lightIndices[i] = -1;
            }
            cull.SetLightIndexMap(lightIndices);
        }

    }

    [Conditional("DEVELOPMENT_BUILD"), Conditional("UNITY_EDITOR")]
    void DrawDefaultPipeline(ScriptableRenderContext context, Camera camera)
    {
        if (errorMaterial == null)
        {
            Shader errorShader = Shader.Find("Hidden/InternalErrorShader");
            errorMaterial = new Material(errorShader)
            {
                hideFlags = HideFlags.HideAndDontSave
            };
        }

        var drawSettings = new DrawRendererSettings(
            camera, new ShaderPassName("ForwardBase")
        );

        drawSettings.SetShaderPassName(1, new ShaderPassName("PrepassBase"));
        drawSettings.SetShaderPassName(2, new ShaderPassName("Always"));
        drawSettings.SetShaderPassName(3, new ShaderPassName("Vertex"));
        drawSettings.SetShaderPassName(4, new ShaderPassName("VertexLMRGBM"));
        drawSettings.SetShaderPassName(5, new ShaderPassName("VertexLM"));

        drawSettings.SetOverrideMaterial(errorMaterial, 0);

        var filterSettings = new FilterRenderersSettings(true);

        context.DrawRenderers(
            cull.visibleRenderers, ref drawSettings, filterSettings
        );
    }
}
