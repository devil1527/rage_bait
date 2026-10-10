# Retro Rage Arcade — Coin Hell

**Retro Rage Arcade** is an original 2D retro pixel-art-inspired arcade game collection built in **Godot 4**.
This repository contains the first playable milestone featuring **COIN HELL** — Level 1.

> *"Collect every coin. Trust nothing."*

---

## 🕹 Features in Milestone 1

- **Forced Landscape Orientation**:
  - The entire app is locked to landscape orientation at the project, export, and runtime levels (`orientation=0`).
  - Optimized for 960x540 base viewport with responsive aspect expansion for modern Android screen ratios.
- **Retro Arcade Main Menu (2x2 Landscape Grid)**:
  - 4 Game Cards arranged in a balanced 2x2 grid utilizing the full landscape canvas:
    - **Coin Hell** (Playable Now) — highlighted with arcade gold borders, warm glow, and vivid "PLAY NOW" badge.
    - **Bullet Betrayal** (Coming Soon) — styled in cyber slate with "COMING SOON" feedback modal.
    - **Ninja Nightmare** (Coming Soon) — styled in cyber slate with "COMING SOON" feedback modal.
    - **Castle of Lies** (Coming Soon) — styled in cyber slate with "COMING SOON" feedback modal.
  - Audio toggle (SFX On/Off) with procedural retro synthesised chiptune audio.
- **Coin Hell Level Select (5x4 Landscape Grid)**:
  - Clear 5-column × 4-row grid displaying all 20 planned levels simultaneously with zero dead space.
  - Distinct styling for Completed (emerald), Available (gold), and Locked (slate) states.
  - Progressive unlocks: Level 1 available on fresh save; completing Level 1 unlocks Level 2.
  - Locked level and unimplemented level dialogue feedback (no blank or crashing scenes).
- **Playable Level 1 ("The Warm-Up")**:
  - Full landscape side-scrolling platforming with acceleration, deceleration, coyote time, and jump buffering.
  - 10 collectible gold coins with subtle floating animation.
  - Gentle surprise mechanic on the 10th coin.
  - Compact top HUD strip (`COINS: X / 10`, level title, pause button) preserving full viewport for gameplay.
  - Closed exit gate displaying remaining required coins, opening only upon collecting all 10 coins.
  - Hazard spikes and pit detection with full retry/respawn flow.
  - Pause overlay with Resume, Restart, Level Select, and SFX toggle.
  - Level Complete overlay with Replay, Level Select, and Next Level flow.
- **On-Screen Mobile Touch Controls**:
  - Ergonomic Left, Right, and Jump touch buttons in bottom corners with visual pressed feedback.
- **Local Save System**:
  - Persists completed levels and unlocked stages to `user://retro_rage_save.json`.
  - Automatic fallback to safe defaults on missing or corrupted data.
- **Automated Headless Test Suite**:
  - 75 automated assertions covering persistence, game data, UI flows, and physics mechanics.

---

## 🚀 How to Run Locally

### Requirements
- **Godot 4.x** (Standard 64-bit release, e.g. Godot 4.3 or 4.7).

### In the Godot Editor
1. Open the Godot Engine.
2. Click **Import** and select the `project.godot` file in this repository.
3. Click **Import & Edit**.
4. Press **F5** (or click the Play icon in the top right) to launch the Main Menu.

### From Command Line / Terminal
To run the game directly:
```bash
godot res://scenes/ui/main_menu.tscn
```

To run the automated headless test suite:
```bash
godot --headless "res://scenes/tests/test_runner.tscn"
```

---

## 🎮 Controls

### Desktop Keyboard
- **Move Left**: `A` or `Left Arrow`
- **Move Right**: `D` or `Right Arrow`
- **Jump**: `Space`, `W`, or `Up Arrow`
- **Pause**: `Escape`

### Android / Touchscreen
- **Left Arrow Button**: Move left
- **Right Arrow Button**: Move right
- **Up Arrow Button**: Jump
- **Pause Button (Top Right)**: Open Pause Menu

---

## 📁 Project Architecture

```text
res://
  ├── project.godot                     # Godot project configuration
  ├── export_presets.cfg                # Android APK export preset
  ├── README.md                         # Documentation and run instructions
  ├── .gitignore                        # Godot 4 gitignore rules
  ├── docs/
  │   ├── ANTIGRAVITY_IMPLEMENTATION_SPEC.md   # Source specification
  │   └── TEST_PLAN.md                  # Comprehensive verification plan
  ├── scenes/
  │   ├── ui/
  │   │   ├── main_menu.tscn            # 4-card arcade hub
  │   │   └── coin_hell_level_select.tscn # 20-level progressive grid
  │   ├── coin_hell/
  │   │   ├── coin_hell_level_1.tscn    # Playable platformer level
  │   │   ├── player.tscn               # Player CharacterBody2D
  │   │   ├── coin.tscn                 # Collectible coin Area2D
  │   │   ├── exit_gate.tscn            # Locked / Unlocked exit gate Area2D
  │   │   └── spikes.tscn               # Hazard Area2D
  │   ├── shared/
  │   │   ├── pause_overlay.tscn        # Pause menu modal
  │   │   ├── death_overlay.tscn        # Respawn/retry modal
  │   │   └── level_complete_overlay.tscn # Victory and progression modal
  │   └── tests/
  │       └── test_runner.tscn          # Automated test execution scene
  ├── scripts/
  │   ├── autoload/
  │   │   ├── game_manager.gd           # Level catalogue & game flow state
  │   │   ├── save_manager.gd           # Local user:// JSON persistence
  │   │   └── audio_manager.gd          # Procedural retro chiptune audio
  │   ├── ui/
  │   │   ├── main_menu.gd
  │   │   └── coin_hell_level_select.gd
  │   ├── coin_hell/
  │   │   ├── player.gd
  │   │   ├── coin.gd
  │   │   ├── exit_gate.gd
  │   │   ├── spikes.gd
  │   │   └── level_1.gd
  │   ├── shared/
  │   │   ├── pause_overlay.gd
  │   │   ├── death_overlay.gd
  │   │   └── level_complete_overlay.gd
  │   └── tests/
  │       └── test_runner.gd            # Test suite assertions
  ├── assets/
  │   └── sprites/                      # Original pixel art PNG assets
  └── .github/
      └── workflows/
          └── android-apk.yml           # CI workflow: tests & Android debug APK
```

---

## 🤖 CI & Android APK Export

The GitHub Actions workflow [`.github/workflows/android-apk.yml`](file:///.github/workflows/android-apk.yml):
1. Sets up Ubuntu with OpenJDK 17 and Android SDK build tools.
2. Downloads Godot 4 headless and official export templates.
3. Headlessly imports all assets and runs the 75-assertion test suite.
4. Exports a debug Android APK to `build/coin-hell-debug.apk`.
5. Uploads the debug APK as a GitHub Actions workflow artifact for direct installation on mobile devices.
