using UnityEngine;

public class TempInstancedMaterialProperties : MonoBehaviour
{
    //static MaterialPropertyBlock propertyBlock;
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

    [SerializeField]
    float pulseEmissionFreqency;

    [SerializeField]
    Material _material;

    [SerializeField]
    Material _material2;

    void Awake()
    {
        setMaterial();
        if (pulseEmissionFreqency <= 0f)
        {
            //enabled = false;
        }
    }

    void Update()
    {
        //Color originalEmissionColor = emissionColor;
        //emissionColor *= 0.5f +
        //    0.5f * Mathf.Cos(2f * Mathf.PI * pulseEmissionFreqency * Time.time);
        //setMaterial();
        //DynamicGI.SetEmissive(GetComponent<MeshRenderer>(), emissionColor);
        //emissionColor = originalEmissionColor;
    }

    void setMaterial()
    {
        //if (propertyBlock == null)
        //{
        //    propertyBlock = new MaterialPropertyBlock();
        //}
        //propertyBlock.SetColor(emissionColorId, emissionColor);
        //propertyBlock.SetColor(colorID, color);
        //propertyBlock.SetFloat(metallicId, metallic);
        //propertyBlock.SetFloat(smoothnessId, smoothness);
        //GetComponent<MeshRenderer>().SetPropertyBlock(propertyBlock);

        if (_material == null)
        {
            GetComponent<MeshRenderer>().material.SetColor(emissionColorId, emissionColor);
            GetComponent<MeshRenderer>().material.SetColor(colorID, color);
            GetComponent<MeshRenderer>().material.SetFloat(metallicId, metallic);
            GetComponent<MeshRenderer>().material.SetFloat(smoothnessId, smoothness);
        }

        if (_material2 == null)
        {
            GetComponent<MeshRenderer>().material.SetColor(emissionColorId, emissionColor);
            GetComponent<MeshRenderer>().material.SetColor(colorID, color);
            GetComponent<MeshRenderer>().material.SetFloat(metallicId, metallic);
            GetComponent<MeshRenderer>().material.SetFloat(smoothnessId, smoothness);
        }
    }
}