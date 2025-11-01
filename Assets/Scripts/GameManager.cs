using System.Collections.Generic;
using UnityEngine;

public class GameManager : MonoBehaviour
{
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    [SerializeField]
    public Camera playerCamera;

    [SerializeField]
    public List<Material> psMaterials;

    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Vector4 playerPos = new Vector4(playerCamera.transform.position.x, playerCamera.transform.position.y, playerCamera.transform.position.z, 1.0f);
        foreach (var mat in psMaterials)
        {
            mat.SetVector("_LightPos", playerPos);
        }
    }
}
