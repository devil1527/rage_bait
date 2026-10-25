# Retro Rage Arcade — Coin Hell

**Retro Rage Arcade** is a precision 2D retro pixel-art platformer collection built in **Godot 4.7.2** targeting **Android API 36 (Android 16)** with **16 KB memory page alignment**.
The featured flagship mode, **COIN HELL**, offers 16 fully implemented, hand-crafted precision platforming stages across 4 distinct worlds.

> *"Collect every coin. Trust nothing."*

---

## 🕹 Features & World Progression (Stages 1–16)

- **World 1: NEON RUINS (Stages 1–5)**:
  - Atmospheric neon-ruin aesthetic with cracked ancient stone and vibrant cyan/magenta highlights.
  - Hazards: Moving walls, collapsing flagstones, ceiling crushers, emerging wall spikes, and deceptive fake exit gates.
- **World 2: HAUNTED HALL (Stages 6–10)**:
  - Eerie gothic castle theme with undulating spectral ghosts, purple wisps, and floating stone platforms.
  - Hazards: Intangible phantom platforms, cursed wind forces with shelter zones, pendulum chains, and the climactic **Stage 10 Boss Survival Arena** (a 60-second multi-round gauntlet with dynamic hazard variations).
- **World 3: RAGE FACTORY (Stages 11–15)**:
  - Heavy industrial foundry aesthetic with rust, iron girders, steam vents, and rotating cogs.
  - Hazards: Dynamic conveyor belts, pneumatic piston crushers, narrow climbing chasms, and the climactic **Stage 15 Rage Furnace** (a 5-phase vertical elevator ascent with rolling boulders and a persistent secret hidden platform).
- **World 4: FINAL HELL (Stages 16–20)**:
  - Apocalyptic infernal aesthetic with black obsidian platforms, glowing runes, rising ash/ember particles, and molten lava chasms.
  - **Stage 16: "The Platform That Lied"**:
    - **Hell Runes**: Rapid crackling warning ($0.38\text{s}$) triggering explosive roaring hellfire columns ($0.75\text{s}$).
    - **Infernal Energy Gates**: Dual pylon laser barriers cycling safe windows ($1.4\text{s}$–$1.5\text{s}$) with warning pulses ($0.45\text{s}$–$0.50\text{s}$).
    - **Disappearing Hell Platforms**: Rapidly crumbling obsidian platforms ($0.50\text{s}$).
    - **Signature Ragebait & Secret Platform**: An impossible $230\text{px}$ direct chasm leap ($> 196.17\text{px}$ max reach) requiring a secret intermediate platform at $X = 2435$.
    - **Dual Discovery Routes**: Supported via living landing catch (Route A) or failed chasm plunge (Route B), persisting across retry and revive.
    - **Strategic Coin 10**: Suspended at $(2510, 180)$ between platforms to tempt players into the impossible leap, collectible cleanly on Jump 2 from the secret platform.
- **Controls & Optimization**:
  - Ergonomic mobile touch controls (Left, Right, Jump) with multi-touch support.
  - Standardized player kinematics (`speed = 240.0`, `jump = -470.0`, `gravity = 1150.0`, coyote time, jump buffer).
  - Landscape orientation ($960 \times 540$) with responsive aspect-expansion.
- **Automated Verification**:
  - Comprehensive automated test runner with **2,777 passed assertions (0 failures)**.

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
          ├── android-api36-validation.yml # Headless test suite & 16KB APK validation
          └── android-release-aab.yml      # Signed Google Play AAB build & validation
```

---

## 🌿 Dual-Branch Architecture

- **`migration/android-api36-godot47` (Active Development)**:
  - Active development branch for new level content, experimental traps, and gameplay tuning.
  - Retains the developer bypass interface (secret 5-tap gesture) for testing any stage directly.
- **`release/play` (Google Play Release Candidate)**:
  - Production release branch tracked at `origin/release/play`.
  - All developer bypass mechanisms stripped; strict sequential progression enforced for players.
  - Tagged `v0.13.0` (`versionCode = 13`, `versionName = "0.13.0"`).

---

## 🤖 CI & Automated Verification

Automated GitHub Actions workflows ensure full regression protection on every push:
1. **Headless Godot 4.7.2 Test Suite**: Executes 2,777 automated assertions covering save integrity, UI navigation, and platforming kinematics.
2. **Android 16 KB Page Alignment**: Verifies 16 KB native ELF memory segment alignment (`readelf -lW`) across 64-bit architectures (`arm64-v8a`, `x86_64`).
3. **Android API 36 & AAB Packaging**: Exports signed Google Play App Bundles (`.aab`) with `zipalign -p -f 16384`.
