using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class LitShaderGUI : ShaderGUI
{
    MaterialEditor editor;
    Object[] materials;
    MaterialProperty[] properties;

    public override void OnGUI(
        MaterialEditor materialEditor, MaterialProperty[] properties
    )
    {
        base.OnGUI(materialEditor, properties);

        editor = materialEditor;
        materials = materialEditor.targets;
        this.properties = properties;
    }

    void SetPassEnabled(string pass, bool enabled)
    {
        foreach (Material m in materials)
        {
            m.SetShaderPassEnabled(pass, enabled);
        }
    }

    bool? IsPassEnabled(string pass)
    {
        bool enabled = ((Material)materials[0]).GetShaderPassEnabled(pass);
        for (int i = 1; i < materials.Length; i++)
        {
            if (enabled != ((Material)materials[i]).GetShaderPassEnabled(pass))
            {
                return null;
            }
        }
        return enabled;
    }
}