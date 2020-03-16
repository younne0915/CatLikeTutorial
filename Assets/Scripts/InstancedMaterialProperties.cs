using UnityEngine;

public class InstancedMaterialProperties : MonoBehaviour
{
    static MaterialPropertyBlock propertyBlock;
    static int colorID = Shader.PropertyToID("_Color");
    static int metallicId = Shader.PropertyToID("_Metallic");
    static int smoothnessId = Shader.PropertyToID("_Smoothness");
    static int emissionColorId = Shader.PropertyToID("_EmissionColor");

    [SerializeField]
    Color color = Color.white;

    [SerializeField, ColorUsage(false, true)]
    Color emissionColor = Color.black;

    [SerializeField, Range(0f, 1f)]
    float metallic;

    [SerializeField, Range(0f, 1f)]
    float smoothness = 0.5f;

    void Awake()
    {
        OnValidate(); 
    }

    void OnValidate()
    {
        if (propertyBlock == null)
        {
            propertyBlock = new MaterialPropertyBlock();
        }
        propertyBlock.SetColor(emissionColorId, emissionColor);
        propertyBlock.SetColor(colorID, color);
        propertyBlock.SetFloat(metallicId, metallic);
        propertyBlock.SetFloat(smoothnessId, smoothness);
        GetComponent<MeshRenderer>().SetPropertyBlock(propertyBlock);
    }
}