# THE HOLLOWS — Unity Horror Project

## Quick Start
1. Open in **Unity 2023.2.20f1** (HDRP template)
2. Open `Assets/Scenes/MainMenu.unity`
3. Assign references in Inspector (see Setup below)
4. Press Play

## Scene Setup

### MainMenu Scene
- Create a `UIDocument` GameObject → assign `Assets/UI/MainMenu.uxml`
- Add `MainMenuController.cs` component → link UIDocument
- Set `gameSceneName = "GameScene"`

### GameScene
- Create Player GameObject:
  - Add `CharacterController`
  - Add `PlayerController.cs`
  - Create child `CameraTarget` Transform (at shoulder, offset X+0.5, Y+1.6)
  - Create child `Flashlight` with a `SpotLight` → assign to flashlightObject
- Add `SaveManager.cs` to a persistent GameObject → link PlayerController

## GitHub CI/CD
Push any commit to `main` → build starts automatically.
Push a tag like `v1.0.0` → GitHub Release is created with a downloadable `.zip`.

### Required Secrets
| Secret | Description |
|--------|-------------|
| `UNITY_LICENSE` | Contents of your `.ulf` file |
| `UNITY_EMAIL` | Your Unity account email |
| `UNITY_PASSWORD` | Your Unity account password |

Get a `.ulf` file: `unity-editor -batchmode -createManualActivationFile` → activate at https://license.unity3d.com/manual

## Controls
| Key | Action |
|-----|--------|
| WASD | Move |
| Shift | Sprint |
| C / Left Ctrl | Crouch |
| E / Left Click | Interact |
| F | Flashlight |
| Tab / I | Inventory |
| Esc | Pause |
| F5 | Quick Save |
| F9 | Quick Load |

## File Structure
```
TheHollows/
├── Assets/
│   ├── Scripts/
│   │   ├── UI/MainMenuController.cs
│   │   ├── Player/PlayerController.cs
│   │   └── Systems/SaveSystem.cs + SaveManager.cs
│   ├── UI/MainMenu.uxml + MainMenu.uss
│   └── Scenes/ (create MainMenu + GameScene in Unity)
├── Packages/manifest.json
├── ProjectSettings/ProjectSettings.asset
├── .github/workflows/build.yml     ← CI/CD
└── Installer/TheHollows_Installer.iss
```

## Save File Location
`Documents/TheHollows/save.dat` (binary, local only, no internet)
