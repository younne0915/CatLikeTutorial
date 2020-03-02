using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Test : MonoBehaviour
{
    public Transform t;

    // Start is called before the first frame update
    void Start()
    {
        //StartCoroutine(CreateCorotine());
    }

    IEnumerator CreateCorotine()
    {
        Vector3 deltPos = Vector3.zero;
        float s = Random.Range(0, 1);
        Vector3 scaleDelt = new Vector3(s, s, s);
        Transform trans = null;
        for (int i = 0; i < 1000; i++)
        {
            deltPos.x = Random.Range(-3, 3);
            deltPos.y = Random.Range(-2, 4);
            deltPos.z = Random.Range(-3, 28);

            trans = Instantiate(t) as Transform;
            trans.position = t.position + deltPos;
            trans.localScale = scaleDelt;
            yield return null;
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
