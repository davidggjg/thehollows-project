using UnityEngine;
using UnityEngine.UIElements;
using UnityEngine.SceneManagement;

/// <summary>
/// Controls the Main Menu UI. Attach to a GameObject with a UIDocument component.
/// </summary>
public class MainMenuController : MonoBehaviour
{
    [Header("UI Document")]
    [SerializeField] private UIDocument uiDocument;
    [Header("Scene Names")]
    [SerializeField] private string gameSceneName = "GameScene";

    private VisualElement _mainPanel, _settingsPanel, _controlsPanel, _root;
    private const string CONTROLS_SHOWN_KEY = "ControlsShownOnce";

    private void OnEnable()
    {
        _root          = uiDocument.rootVisualElement;
        _mainPanel     = _root.Q<VisualElement>("MainPanel");
        _settingsPanel = _root.Q<VisualElement>("SettingsPanel");
        _controlsPanel = _root.Q<VisualElement>("ControlsPanel");

        _root.Q<Button>("BtnNewGame") .clicked += OnNewGame;
        _root.Q<Button>("BtnLoadGame").clicked += OnLoadGame;
        _root.Q<Button>("BtnSettings").clicked += () => ShowPanel(_settingsPanel);
        _root.Q<Button>("BtnExit")    .clicked += OnExit;

        _root.Q<Button>("BtnControls")        .clicked += () => ShowPanel(_controlsPanel);
        _root.Q<Button>("BtnBackFromSettings").clicked += () => ShowPanel(_mainPanel);
        _root.Q<Button>("BtnBackFromControls").clicked += OnBackFromControls;

        ShowPanel(PlayerPrefs.HasKey(CONTROLS_SHOWN_KEY) ? _mainPanel : _controlsPanel);
    }

    private void ShowPanel(VisualElement t)
    {
        foreach (var p in new[]{ _mainPanel, _settingsPanel, _controlsPanel })
            p.style.display = DisplayStyle.None;
        t.style.display = DisplayStyle.Flex;
    }

    private void OnNewGame()  { SaveSystem.DeleteSave(); SceneManager.LoadScene(gameSceneName); }
    private void OnLoadGame() { if (SaveSystem.SaveExists()) SceneManager.LoadScene(gameSceneName); }
    private void OnBackFromControls() { PlayerPrefs.SetInt(CONTROLS_SHOWN_KEY,1); PlayerPrefs.Save(); ShowPanel(_mainPanel); }
    private void OnExit()
    {
#if UNITY_EDITOR
        UnityEditor.EditorApplication.isPlaying = false;
#else
        Application.Quit();
#endif
    }
}
