# 🕯️ THE HOLLOWS
> *A psychological survival horror game. You were never meant to leave.*

Built with **Godot 4.6** · Builds automatically to Windows EXE via GitHub Actions · No Unity License required

---

## 📁 Project Structure

```
TheHollows_Godot/
├── .github/workflows/build.yml        ← CI/CD: auto-builds EXE
└── game/
    ├── project.godot                  ← Open this in Godot 4.6
    ├── export_presets.cfg             ← Windows export config
    ├── scripts/
    │   ├── systems/
    │   │   ├── GameManager.gd         ← Global: state, levels, checkpoints
    │   │   ├── SaveSystem.gd          ← Global: local save/load
    │   │   ├── AudioManager.gd        ← Global: music, SFX, heartbeat
    │   │   ├── FearSystem.gd          ← Global: fear, sanity, hallucinations
    │   │   ├── LevelBase.gd           ← Base class for all levels
    │   │   ├── Level1Controller.gd    ← Level 1: Apartment
    │   │   ├── Interactable.gd        ← Base: doors, items, hide spots
    │   │   ├── Door.gd                ← Animated doors with locks
    │   │   ├── PickupItem.gd          ← Collectible items & notes
    │   │   └── HideSpot.gd            ← Locker/closet hide mechanics
    │   ├── player/
    │   │   └── Player.gd              ← Full 3rd-person controller
    │   ├── enemies/
    │   │   └── Creature.gd            ← Enemy AI (patrol/hunt/attack)
    │   └── ui/
    │       ├── MainMenu.gd            ← Main menu with settings
    │       └── HUD.gd                 ← In-game HUD, fear overlay
    └── assets/shaders/
        ├── horror_postprocess.gdshader ← Fear/sanity visual FX
        └── interactable_highlight.gdshader
```

---

## 🚀 How to Build (GitHub Actions — 0 setup required)

### Every push to `main`:
→ Builds automatically, uploads artifact

### To create a downloadable Release:
```bash
git tag v1.0.0
git push origin v1.0.0
```
→ GitHub builds `TheHollows.exe`, packages it in a ZIP, creates a Release page.

**No secrets. No licenses. No payment. It just works.**

---

## 🎮 How to Open in Godot Editor

1. Download **Godot 4.6** from https://godotengine.org
2. Open Godot → Import → select `game/project.godot`
3. Press F5 to run

### First thing to do in Editor:
- Create scenes for: `MainMenu.tscn`, `Level1_Apartment.tscn`, `HUD.tscn`
- Add a `CharacterBody3D` node for Player → attach `Player.gd`
- Add a `CharacterBody3D` node for Creature → attach `Creature.gd`
- Add `WorldEnvironment` node → enable SDFGI + Volumetric Fog
- Import your 3D models (FBX/GLB) into `assets/models/`

---

## 🎨 Visual Quality Setup (in Godot Editor)

### WorldEnvironment settings for maximum horror:
```
Rendering:
  ✅ Forward+
  ✅ SDFGI (Global Illumination)
  ✅ Volumetric Fog — density 0.05, albedo dark grey
  ✅ SSAO — radius 1.5, intensity 2.0
  ✅ SSIL — spread 5.0
  ✅ Glow — threshold 0.8, bloom 0.1
  ✅ TAA (Temporal Anti-Aliasing)
  ✅ Screen-Space Reflections

Sky: Black / pitch dark
Ambient light: 0.02 (near-zero — only flashlight illuminates)
```

---

## 🕹️ Controls
| Key | Action |
|---|---|
| WASD | Move |
| Shift | Sprint (makes noise — creature hears you) |
| C | Crouch (quieter, harder to see) |
| E | Interact (doors, items, notes) |
| F | Flashlight (creature can see the beam) |
| Tab | Inventory / Journal |
| H | Enter/exit hiding spot |
| Esc | Pause menu |
| F5 | Quick Save |
| F9 | Quick Load |

---

## 🧠 Systems Overview

### FearSystem
- `fear_level` (0-1): drives vignette, heartbeat, chromatic aberration
- `sanity` (0-100): depletes at high fear → hallucinations
- Creature proximity, darkness, sprinting all raise fear

### Creature AI
- **PATROL** → follows patrol path
- **INVESTIGATE** → heard/saw something, searching
- **HUNT** → knows where you are, running at full speed
- **ATTACK** → in range, deals damage
- Hears sprinting (18m), crouching (6m), flashlight beam (25m)

### Save System
- Saves to `user://saves/save_slot_0.dat` (JSON)
- Windows path: `%AppData%\Roaming\Godot\app_userdata\TheHollows\saves\`
- Auto-saves at every checkpoint

---

## 🗺️ The Story

**Vesper Towers, 1994.** You are a forensic archivist sent to recover documents from a condemned Soviet-era apartment complex. Behind a wall in Sub-Basement B2, you find a flooded tunnel. The tunnel leads to **Ashford Psychiatric Institute** — sealed by government order in 1987 after an experimental treatment program erased the boundary between patient and predator.

The documents you need are in the deepest part of the Institute. Something that used to be Dr. Ashford is between you and them. It remembers what it was. It doesn't forgive you for coming.

**3 Endings. 20+ collectible notes. 6-8 hours of gameplay.**
