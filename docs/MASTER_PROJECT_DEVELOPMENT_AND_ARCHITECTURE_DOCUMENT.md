# RETRO RAGE ARCADE (COIN HELL)
## Complete Development History, Technical Architecture & Master Specification

---

## 1. Executive Summary & Game Pillars

**Retro Rage Arcade** is a precision mobile retro platformer developed in **Godot 4** with **GDScript**. The featured mode, **Coin Hell**, challenges players to navigate precision gauntlets, collect every required coin (typically 10 per level), and survive intense environmental traps.

### Platform Specifications
- **Target Platform:** Android (Mobile)
- **Screen Orientation:** Landscape (`screen/orientation=0`)
- **Base Resolution:** $960 \times 540$ pixels (16:9 widescreen)
- **Window Stretch Mode:** `canvas_items`, aspect `keep`
- **Control Scheme:** Standardized on-screen touch controls with multi-touch support:
  - Left / Right directional buttons ($104 \times 104\text{px}$)
  - Jump button ($124 \times 124\text{px}$)
  - Full keyboard fallback (Left/Right arrow keys, A/D, Space/Up for Jump)

### Core Gameplay Pillars
1. **Precision Platforming:** Deterministic player physics, predictable gravity, jump buffering, and coyote time.
2. **Fair Rage-Bait Design:** Traps (spikes, phantom platforms, swinging chains, crumbling ground) are sudden and challenging, but always provide clear visual and audible warnings ($\ge 0.6\text{s}$ reaction window).
3. **Anti-Camping Enforcement:** Players cannot exploit static safe zones. In survival arenas, lingering on any platform triggers hazards within 5–6 seconds.
4. **Instant Restart & Flow:** Death triggers immediate visual feedback with a 1-tap retry that completely resets the arena, traps, and coins without reloading the engine.

---

## 2. Global Architecture & Core Autoloads

```mermaid
graph TD
    Player[Player Controller Body2D] --> GameManager
    Level[Level Scene / Survival Arena] --> GameManager
    Level --> SaveManager
    Level --> AudioManager
    TouchUI[HUD TouchControls] --> Player
    GameManager --> SaveManager
    GameManager --> AudioManager
```

### 2.1 GameManager (`scripts/autoload/game_manager.gd`)
- Tracks active level state, coins collected, target coins required, death events, and victory conditions.
- Coordinates progression between levels (Levels 1 to 20 defined).
- Dispatches global signals:
  - `coin_collected(current, total)`
  - `coins_reset()`
  - `player_died()`
  - `level_completed(level_id)`

### 2.2 SaveManager (`scripts/autoload/save_manager.gd`)
- Handles persistent progression in `user://coin_hell_save.json`.
- Safely manages `highest_unlocked_level`, completion status per level, and coin records.
- Implements corruption resistance: if the save file is corrupted or unreadable, safe defaults are loaded without crashing.

### 2.3 AudioManager (`scripts/autoload/audio_manager.gd`)
- Employs procedural/synthesized 8-bit retro sound effects:
  - `jump`: Retro pitch bend upwards.
  - `coin`: Double chimes.
  - `death`: Noise burst and descending tone.
  - `flame`: Spectral whoosh for hazard activation.
  - `click`: UI feedback.
  - `wind`: Atmospheric breeze loop.
  - `chain`: Metallic rattle and thud.

### 2.4 TouchControls (`scripts/coin_hell/touch_button.gd` & UI Scenes)
- Standardized tactile mobile touch overlay with active states, release callbacks, and screen touch index tracking to support simultaneous running and jumping.

---

## 3. Chronological Work History & Prompt Evolution

This section details every milestone, user prompt, architectural requirement, challenge encountered, and technical solution implemented throughout the development cycle.

```mermaid
timeline
    title Retro Rage Arcade Development Milestones
    Milestone 1 : World 2 Visuals : Level 6 Polish : Level 7 Implementation
    Milestone 2 : Level 7 Bug Fixes : Level 8 Cursed Wind
    Milestone 3 : Level 8 Rebalance : Shelter Zones & Reachability
    Milestone 4 : Level 9 Chains of the Damned : Pendulum Chains
    Milestone 5 : Level 9 HUD Swap Fix : Level 10 Boss Stage Architecture
    Milestone 6 : Level 10 10-Round Schedule : Anti-Camping Engine
    Milestone 7 : Level 10 Dynamic Hazard System : 5 Chains & Attempt Variation
```

---

### Milestone 1: World 2 Visual Redesign + Level 6 Polish + Level 7 Implementation

#### Problem Statement
World 2 ("The Haunted Hall") did not feel visually distinct from World 1. It lacked an eerie gothic castle atmosphere. Level 6 needed polish, and Level 7 ("Hall of Illusions") needed to be created from scratch featuring phantom platforms.

#### Key Implementations
1. **World 2 Atmospheric System (`HauntedHallEnvironment`):**
   - Parallax scrolling background with gothic stone architecture and arches.
   - Flying background spectral ghosts moving on undulating sine wave paths.
   - Ghostly wisp particle emitters rising from floor pits.
   - Gothic stone platforms (`haunted_stone_platform.png`) and gothic arches (`gothic_arch.png`).
2. **Level 6 ("Phantom's Curse"):**
   - Introduced the phantom platform concept: stone platforms that periodically dissolve into intangible spectral states.
   - Implemented clear shimmer warnings before phasing out.
   - 10 collectible coins distributed along precision jump arcs.
3. **Level 7 ("Hall of Illusions"):**
   - Built a multi-tier hall featuring staggered phantom platforms with alternating phase cycles.
   - Required players to time jumps between platforms as they solidified.
   - Integrated locked Exit Gate that unlocks only when all 10 coins are collected.

---

### Milestone 2: Level 7 Bug Fixes & Level 8 Cursed Wind Implementation

#### Problem Statement
Two critical bugs were reported in Level 7:
1. **Input Lockout on Death:** When the player died, movement and jump inputs stopped responding permanently, forcing a full game restart.
2. **Platform Desynchronization:** Phantom platforms could get stuck in intangible states upon respawn.
Additionally, Level 8 needed to introduce a new signature environmental hazard: **The Cursed Wind**.

#### Key Implementations
1. **Fixing Player Input Lockout:**
   - Root cause: Player script disabled physics processing and input flags upon death, but `reset_to()` did not reset `_input_disabled`, velocity vectors, or touch button states.
   - Solution: Implemented `revive()` and `reset_to(pos)` methods on `Player` that explicitly restore physics processing, reset velocities to `Vector2.ZERO`, clear touch button presses, and enable collision masks.
2. **Fixing Phantom Platform Reset:**
   - Connected `GameManager.coins_reset` directly to platform reset routines, immediately restoring collision shape monitoring, resetting timers, and returning visual opacity to 1.0.
3. **Level 8 ("The Cursed Wind") Implementation:**
   - Created `CursedWindZone` which applies continuous horizontal aerodynamic force to the player body.
   - Added visual flying wind streaks and howling audio cues.
   - Placed 10 collectible coins across wind-swept chasms.

---

### Milestone 3: Level 8 Gameplay Rebalance

#### Problem Statement
The player attempted Level 8 over 50 times without completing it. The wind force was overwhelming, jump trajectories were unpredictable, and there was no respite or clear route.

#### Key Implementations
1. **Wind Force & Timing Calibration:**
   - Reduced continuous wind force from harsh gusts to manageable atmospheric drift.
   - Converted the wind into a **cyclical gust system**: 2.5s of active wind followed by 2.0s of calm wind, allowing players to plan moves.
2. **Shelter & Sanctuary Zones:**
   - Added solid gothic pillars and architectural arches that act as windbreaks. Standing behind a pillar completely negates wind push.
3. **Platform Reachability:**
   - Widened landing platforms by 20–30px.
   - Ensured all coin jumps are mathematically reachable even against max headwind.

---

### Milestone 4: Level 9 — Chains of the Damned

#### Problem Statement
Implement Level 9 ("Chains of the Damned") introducing a new hazard: **Swinging Pendulum Chains**, with exactly 10 coins and locked exit gate.

#### Key Implementations
1. **Swinging Ghost Chain System (`SwingingChain`):**
   - Segmented pendulum body with ceiling anchor mount, links, and heavy spiked weight.
   - Simple harmonic motion:
     $$\theta(t) = \theta_{\max} \cdot \sin(\omega t + \phi)$$
   - Dual-zone collision: the heavy weight and bottom 40% of the chain are lethal (`Area2D` on layer 4), while the upper mount allows jumping through.
2. **Level 9 Arena Design:**
   - 5 massive swinging chains guarding consecutive platform tiers.
   - Sanctuary resting platforms between chains.
   - 10 collectible coins placed inside the swing arcs, requiring players to time their leaps into the rhythm of the pendulums.
   - Locked Exit Gate at the summit resting flush on the final sanctuary platform.

---

### Milestone 5: Level 9 HUD Swap Fix & Level 10 Boss Stage Architecture

#### Problem Statement
1. In Level 9, the Coin Counter and Pause Button were accidentally swapped in the HUD top bar.
2. Implement Level 10 ("Haunted Survival"), the climax of World 2, featuring a dramatic boss stage introduction, a 60-second survival objective, and five platform hazards.

#### Key Implementations
1. **Level 9 HUD Ordering:**
   - Restored standard layout: CoinCounter on top-left (child 0), LevelName centered (child 1), TimerContainer (child 2), and PauseBtn on top-right (child 3).
2. **Level 10 Architecture ("Haunted Survival"):**
   - **Fixed Arena:** Fixed $960 \times 540$ arena with no camera scrolling (`limit_left = 0`, `limit_right = 960`, `limit_top = 0`, `limit_bottom = 540`).
   - **Boss Intro Flow:** `BossIntroOverlay` displays "SURVIVE FOR 1 MINUTE!" with objective instructions. Player input is disabled during intro.
   - **Survival Timer:** Continuous 60-second countdown in the HUD top bar.
   - **5 Platform Survival Arena:**
     - Platform 1: Spikes
     - Platform 2: Phantom
     - Platform 3: Crumbling
     - Platform 4: Chains
     - Platform 5: Countdown
   - **Surprise Ghost Chain:** Emerges from ceiling rifts, swings through an attack arc, and retracts.
   - **Boss Victory Overlay:** Triggers at $t = 60.0\text{s}$, unlocks Level 11 (World 3) in `SaveManager`, and displays "WORLD 2 COMPLETE!".

---

### Milestone 6: Level 10 Anti-Camping Redesign & 10-Round Schedule

#### Problem Statement
Level 10 was too easy because players could complete the stage simply by standing still on Platform 1 or 2 for the full minute. The stage needed active anti-camping mechanics, round transitions, and dynamic coin spawns.

#### Key Implementations
1. **Ten Six-Second Rounds:**
   - 60 seconds divided into 10 distinct 6-second rounds (Rounds 1 through 10).
   - HUD TopBar displays `[R1/10]` through `[R10/10]`.
   - Dynamic banner popups announce each round transition.
2. **Dynamic Coin Spawning:**
   - Exactly 1 coin spawned per round (10 coins total across the attempt).
   - Spawns at $t = 0\text{s}, 6\text{s}, 12\text{s}, 18\text{s}, 24\text{s}, 30\text{s}, 36\text{s}, 42\text{s}, 48\text{s}, 54\text{s}$.
3. **Anti-Camping Rotation:**
   - Scheduled hazards deliberately target platforms in sequence (P1 in R1, P2 in R2, P3 in R3, P4 in R4, P5 in R5), guaranteeing that standing still is punished within 5–6 seconds.
4. **Final Countdown Alerts:**
   - Prominent alert banner at 50s elapsed ("10 SECONDS LEFT! DON'T DIE NOW!").
   - Large pulsing numerical countdown for the final 5 seconds (5, 4, 3, 2, 1).

---

### Milestone 7: Level 10 Dynamic Hazard System & Multi-Chain Overhaul

#### Problem Statement
Even with the 10-round schedule, hazard locations were fixed:
- Spikes always appeared on Platform 1 (left).
- Only Platform 2 vanished as phantom.
- Only Platform 3 crumbled.
- Only one chain existed at $X = 620$.
The system needed full spatial and positional dynamic variation across the arena, multiple ceiling chains (1, 2, or 3 chains), and controlled attempt variation.

#### Key Implementations
1. **Dynamic Hazard Override on `SurvivalArenaPlatform`:**
   - Added `trigger_hazard(warn, act, override_type)` allowing *any* platform to execute *any* hazard type (`SPIKES`, `PHANTOM`, `CRUMBLING`, `COUNTDOWN`).
2. **Multiple Ceiling Chain Array (5 Attack Points):**
   - Installed 5 distinct ceiling attachment points spanning the arena:
     - $X = 260$ (`ChainLeft`)
     - $X = 400$ (`ChainMidLeft`)
     - $X = 480$ (`ChainCenter`)
     - $X = 620$ (`SurpriseGhostChain`)
     - $X = 740$ (`ChainRight`)
   - Supported simultaneous multi-chain attacks (dual and triple chains) with non-overlapping trajectories and safe standing corridors.
3. **Controlled Randomization & Attempt Variation:**
   - Created 3 handcrafted, validated variants (Variant 0: Balanced Arena Sweep; Variant 1: Flank Pressure; Variant 2: Apex Pressure).
   - Tracked `_last_attempt_variant` to prevent consecutive repetition on death and retry.
   - Supported `variant_override` for deterministic headless test execution.
4. **Fairness Guarantees:**
   - All warnings $\ge 0.6\text{s}$.
   - Every single hazard wave guarantees at least 2 safe, solid platforms.

---

## 4. Technical Architecture: Level 10 Boss Stage

```
+-----------------------------------------------------------------------------------+
| TopBar: [COINS: 0/10]   WORLD 2 · BOSS: HAUNTED SURVIVAL   [SURVIVE: 60s] [R1/10] |
+-----------------------------------------------------------------------------------+
|  Ceiling Y=50:                                                                    |
|    ChainLeft(260)   ChainMidLeft(400)   ChainCenter(480)   Chain3(620)   ChainR(740)|
|          |                 |                   |                |             |   |
|          v                 v                   v                v             v   |
|                                                                                   |
|                                     [Platform 3]                                  |
|                                      X=480, Y=220                                 |
|                                                                                   |
|                 [Platform 2]                            [Platform 4]              |
|                  X=340, Y=310                            X=620, Y=310             |
|                                                                                   |
|   [Platform 1]                                                          [Platform 5]|
|    X=200, Y=400                                                          X=760, Y=400|
|     (Spawn)                                                                       |
|                                                                                   |
|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Pit Hazard Area (Y=520) ~~~~~~~~~~~~~~~~~~~~~~~~~~|
+-----------------------------------------------------------------------------------+
```

### 4.1 Arena Geometry & Platform Roster

| Platform | Node Name | Arena Position | Width | Default Hazard | Supported Dynamic Hazards |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **P1** | `Platform1_Spikes` | $(200, 400)$ | 160px | Spikes | Spikes, Phantom, Crumbling, Countdown |
| **P2** | `Platform2_Phantom` | $(340, 310)$ | 140px | Phantom | Spikes, Phantom, Crumbling, Countdown |
| **P3** | `Platform3_Crumbling` | $(480, 220)$ | 160px | Crumbling | Spikes, Phantom, Crumbling, Countdown |
| **P4** | `Platform4_Chains` | $(620, 310)$ | 140px | Chains | Spikes, Phantom, Crumbling, Countdown |
| **P5** | `Platform5_Countdown`| $(760, 400)$ | 160px | Countdown | Spikes, Phantom, Crumbling, Countdown |

### 4.2 Ceiling Chains Specification

| ID | Node | Attachment $(X, Y)$ | Swing Angle | Speed | Trajectory Range |
| :---: | :--- | :---: | :---: | :---: | :---: |
| **0** | `ChainLeft` | $(260, 50)$ | $+42.0^\circ$ | 2.5 rad/s | $X \in [180, 340]$ |
| **1** | `ChainMidLeft` | $(400, 50)$ | $-40.0^\circ$ | 2.6 rad/s | $X \in [325, 475]$ |
| **2** | `ChainCenter` | $(480, 50)$ | $+45.0^\circ$ | 2.7 rad/s | $X \in [400, 560]$ |
| **3** | `SurpriseGhostChain`| $(620, 50)$ | $+46.0^\circ$ | 2.4 rad/s | $X \in [540, 700]$ |
| **4** | `ChainRight` | $(740, 50)$ | $-44.0^\circ$ | 2.5 rad/s | $X \in [660, 820]$ |

### 4.3 Curated Variant Schedules

#### Variant 0: Balanced Arena Sweep & Sequential Attacks
- **Round 1 (0–6s):** P1 Spikes (warn 0.8s), Chain 3 ($X=620$). Coin 1 at P2.
- **Round 2 (6–12s):** P2 Phantom, Chain 0 ($X=260$). Coin 2 at P3.
- **Round 3 (12–18s):** P3 Crumbling, P5 Spikes. Coin 3 at P4.
- **Round 4 (18–24s):** Chain 3 ($X=620$), P2 Spikes, P1 Phantom. Coin 4 at P5.
- **Round 5 (24–30s):** P5 Countdown, Dual Chains 1 & 4. Coin 5 at P3.
- **Round 6 (30–36s):** P3 Spikes (Center Apex), P4 Crumbling, Chain 4. Coin 6 at P1.
- **Round 7 (36–42s):** Dual Spikes on P1 & P5 (Flanks), Chain 2 (Center). Coin 7 at P2.
- **Round 8 (42–48s):** P4 Phantom, P2 Spikes, Dual Chains 0 & 3. Coin 8 at P3.
- **Round 9 (48–54s):** Sequential Spikes (P1 at 48.8s $\rightarrow$ P4 at 50.2s), P3 Crumbling, Chain 1. Coin 9 at P5.
- **Round 10 (54–60s):** Dual Spikes on P2 & P5, P1 Phantom, Triple Chains (Chain 0, 2, 4). Coin 10 at P3.

#### Variant 1: Flank Pressure & Dual Assault
- **Round 1 (0–6s):** P1 Spikes, Chain 0 ($X=260$), P5 Spikes. Coin 1 at P3.
- **Round 2 (6–12s):** P4 Phantom, P2 Spikes, Chain 1 ($X=400$). Coin 2 at P5.
- **Round 3 (12–18s):** P2 Crumbling, Dual Chains 0 & 3, P4 Spikes. Coin 3 at P3.
- **Round 4 (18–24s):** P3 Spikes, P5 Phantom, Dual Chains 2 & 4. Coin 4 at P1.
- **Round 5 (24–30s):** P2 Crumbling, P5 Spikes, Dual Chains 0 & 2. Coin 5 at P4.
- **Round 6 (30–36s):** Dual Spikes on P1 & P4, P2 Phantom, Chain 4. Coin 6 at P3.
- **Round 7 (36–42s):** P5 Spikes, P4 Phantom, Dual Chains 0 & 4. Coin 7 at P1.
- **Round 8 (42–48s):** P4 Phantom, P5 Spikes, Dual Chains 1 & 3. Coin 8 at P2.
- **Round 9 (48–54s):** Dual Chains 1 & 4, P4 Phantom, P5 Spikes. Coin 9 at P3.
- **Round 10 (54–60s):** Dual Spikes on P2 & P4, P1 Countdown, Triple Chains (Chain 1, 4, 0). Coin 10 at P3.

#### Variant 2: Apex Pressure & Crumbling Ruins
- **Round 1 (0–6s):** P1 Spikes, Dual Chains 1 & 4. Coin 1 at P4.
- **Round 2 (6–12s):** P3 Phantom (Center Apex vanishes!), P1 Countdown, Chain 3. Coin 2 at P2.
- **Round 3 (12–18s):** P4 Crumbling, P3 Spikes (Apex), Dual Chains 1 & 2. Coin 3 at P1.
- **Round 4 (18–24s):** P1 Phantom, P4 Spikes, Chain 1. Coin 4 at P3.
- **Round 5 (24–30s):** P4 Countdown, P2 Spikes, Chain 4. Coin 5 at P1.
- **Round 6 (30–36s):** Sequential Spikes (P1 at 30.8s $\rightarrow$ P2 at 32.2s), P4 Crumbling, Chain 2. Coin 6 at P5.
- **Round 7 (36–42s):** P3 Crumbling, P2 Spikes, Chain 3. Coin 7 at P4.
- **Round 8 (42–48s):** P3 Spikes (Apex), P1 Crumbling, Dual Chains 0 & 2. Coin 8 at P5.
- **Round 9 (48–54s):** Dual Spikes on P2 & P4, P3 Crumbling, Chain 2. Coin 9 at P1.
- **Round 10 (54–60s):** Dual Spikes on P1 & P3, P4 Crumbling, Triple Chains (Chain 3, 2, 1). Coin 10 at P5.

---

## 5. Verification & Testing Framework

All systems are validated using the Godot headless test runner:
```powershell
& 'C:\Users\hp\godot\Godot_v4.7.2-stable_win64_console.exe' --headless 'res://scenes/tests/test_runner.tscn'
```

### 5.1 Test Suite Summary: 1,388 Passed, 0 Failed

| Test Category | Description | Assertions | Status |
| :--- | :--- | :---: | :---: |
| **Save & Persistence** | Save/load, unlocks, corruption recovery | 9 | **PASS** |
| **Level Definitions** | Level metadata, names, targets for Levels 1–20 | 25 | **PASS** |
| **World 1 Levels (1–5)** | Mechanics, collision, tricks, coin completion | 180 | **PASS** |
| **World 2 Levels (6–8)** | Phantoms, bug fixes, wind zones & shelters | 240 | **PASS** |
| **Level 9 Mechanics** | Pendulum chains, sanctuary platforms, exit gate | 110 | **PASS** |
| **Level 10 Baseline** | Intro overlay, 60s timer, HUD layout, mobile UI | 145 | **PASS** |
| **Level 10 Anti-Camping**| P1–P5 camping rotation, coin timing | 85 | **PASS** |
| **TEST A: Variable Spikes**| Left, Right, Mid, Apex, Dual, Sequential | 120 | **PASS** |
| **TEST B: Phantom Targets**| Variable platforms phasing out & recovering | 90 | **PASS** |
| **TEST C: Multiple Chains**| 5 ceiling mounts, dual & triple attacks | 115 | **PASS** |
| **TEST D: Crumbling Targets**| Variable platforms shaking, falling & restoring | 85 | **PASS** |
| **TEST E: Round Transitions**| 10 six-second rounds & dynamic coin spawns | 50 | **PASS** |
| **TEST F: Attempt Variation**| Variant rotation across retries, non-repetition | 35 | **PASS** |
| **TEST G: Fairness** | Reaction window $\ge 0.6\text{s}$, $\ge 2$ safe platforms | 99 | **PASS** |
| **Total Test Result** | **Full Automated Test Coverage** | **1,388** | **100% PASS** |

---

## 6. Android Export & CI/CD Pipeline

The project uses GitHub Actions to automatically test, export, and package the Android APK on every push to `main`.

### CI Workflow Configuration (`.github/workflows/android-apk.yml`)
1. **Environment:** Ubuntu latest, Temurin JDK 17, Android SDK Platform 34, Build Tools 34.0.0.
2. **Engine:** Godot 4.3 Headless + Godot 4.3 Export Templates.
3. **Keystore:** Persistent debug keystore cached and managed automatically.
4. **Automated Verification:** Runs `godot --headless "res://scenes/tests/test_runner.tscn"`. The build aborts if any test fails.
5. **Export:** Compiles Android Debug APK (`build/coin-hell-debug.apk`) using preset `Android`.
6. **Artifact Upload:** Publishes artifact `coin-hell-debug-apk`.

### Latest Build Verification
- **GitHub Workflow Run:** [Run 38512622966](https://github.com/devil1527/rage_bait/actions/runs/38512622966)
- **Git Commit:** `29f20d5`
- **Android Version:** Code `10` / Name `0.10.0`
- **Result:** `success`
- **Artifact:** `coin-hell-debug-apk` (48,211,423 bytes, ~46 MB)

---

## 7. Developer Quick Reference

### Running the Test Suite Locally
```powershell
cd c:\AntiGravity\rage_bait
& 'C:\Users\hp\godot\Godot_v4.7.2-stable_win64_console.exe' --headless 'res://scenes/tests/test_runner.tscn'
```

### Testing a Specific Level 10 Variant Deterministically
In code or tests:
```gdscript
var lvl = load("res://scenes/coin_hell/coin_hell_level_10.tscn").instantiate()
lvl.variant_override = 1 # 0 = Variant 0, 1 = Variant 1, 2 = Variant 2, -1 = Randomized
add_child(lvl)
```

### Triggering Custom Hazards on Any Platform
```gdscript
# trigger_hazard(warning_duration, active_duration, optional_hazard_override)
platform.trigger_hazard(0.75, 1.8, SurvivalArenaPlatform.HazardType.SPIKES)
```
Valid types:
- `HazardType.SPIKES` (0)
- `HazardType.PHANTOM` (1)
- `HazardType.CRUMBLING` (2)
- `HazardType.CHAINS` (3)
- `HazardType.COUNTDOWN` (4)

### Adding Future Levels (World 3: Level 11+)
1. Create scene under `scenes/coin_hell/coin_hell_level_11.tscn`.
2. Follow HUD TopBar hierarchy: `CoinCounter` (0), `LevelName` (1), `TimerContainer` (2), `PauseBtn` (3).
3. Connect exit gate or survival timer to `GameManager.trigger_level_complete()`.
4. Add unit test suite in `scripts/tests/test_runner.gd` and register in `run_all_tests()`.
