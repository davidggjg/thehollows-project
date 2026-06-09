using System.Collections.Generic;
using UnityEngine;

/// <summary>Attach to a DontDestroyOnLoad GameObject in GameScene.</summary>
public class SaveManager : MonoBehaviour
{
    [SerializeField] private PlayerController playerController;

    [HideInInspector] public string LastCheckpointID = "CP_Start";
    [HideInInspector] public List<string> CurrentInventory = new List<string>();

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.F5)) SaveGame();
        if (Input.GetKeyDown(KeyCode.F9)) LoadGame();
    }

    public void SaveGame()
    {
        if (!playerController) { Debug.LogError("[SaveManager] No PlayerController assigned!"); return; }
        var data = new SaveData
        {
            posX           = playerController.transform.position.x,
            posY           = playerController.transform.position.y,
            posZ           = playerController.transform.position.z,
            healthPercent  = playerController.HealthPercent,
            inventoryItems = new List<string>(CurrentInventory),
            lastCheckpoint = LastCheckpointID
        };
        SaveSystem.Save(data);
    }

    public void LoadGame()
    {
        var data = SaveSystem.Load();
        if (data == null) return;
        playerController.transform.position = new Vector3(data.posX, data.posY, data.posZ);
        playerController.HealthPercent = data.healthPercent;
        CurrentInventory = data.inventoryItems ?? new List<string>();
        LastCheckpointID = data.lastCheckpoint;
        Debug.Log($"[SaveManager] Loaded — {data.saveTimestamp}");
    }
}
