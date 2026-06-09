using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using UnityEngine;

[Serializable]
public class SaveData
{
    public float posX, posY, posZ;
    public float healthPercent;
    public List<string> inventoryItems = new List<string>();
    public string lastCheckpoint = "CP_Start";
    public string saveTimestamp;
    public int saveSlot = 0;
}

public static class SaveSystem
{
    private static readonly string SaveDir =
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "TheHollows");
    private static readonly string SaveFile = Path.Combine(SaveDir, "save.dat");

    public static bool Save(SaveData data)
    {
        try
        {
            data.saveTimestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            Directory.CreateDirectory(SaveDir);
            var fmt = new BinaryFormatter();
            using (var fs = new FileStream(SaveFile, FileMode.Create))
                fmt.Serialize(fs, data);
            Debug.Log($"[SaveSystem] Saved → {SaveFile}");
            return true;
        }
        catch (Exception ex) { Debug.LogError($"[SaveSystem] Save failed: {ex.Message}"); return false; }
    }

    public static SaveData Load()
    {
        if (!SaveExists()) { Debug.LogWarning("[SaveSystem] No save file."); return null; }
        try
        {
            var fmt = new BinaryFormatter();
            using (var fs = new FileStream(SaveFile, FileMode.Open))
                return (SaveData)fmt.Deserialize(fs);
        }
        catch (Exception ex) { Debug.LogError($"[SaveSystem] Load failed: {ex.Message}"); return null; }
    }

    public static bool   SaveExists()  => File.Exists(SaveFile);
    public static void   DeleteSave()  { if (SaveExists()) File.Delete(SaveFile); }
    public static string GetSavePath() => SaveFile;
}
