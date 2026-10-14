# 10-LEVEL ANDROID GAMEPLAY REGRESSION CHECKLIST
## Retro Rage Arcade (Coin Hell) — Physical Device QA Protocol

---

| Protocol Header | Specification |
| :--- | :--- |
| **Target Application** | Retro Rage Arcade (Coin Hell) |
| **Package ID** | `com.antigravity.retroragearcade` |
| **APK Version Code / Name** | `10` / `0.10.0` |
| **Target Android API** | API 36 (Android 16) / Minimum API 24 (Android 7.0) |
| **Test Artifact** | `coin-hell-api36-test.apk` |
| **QA Execution Status** | **NOT TESTED** (Template prepared for physical device testing) |
| **Testing Rule** | **All fields remain blank or NOT TESTED. Never fabricate manual test results.** |

---

## 1. Device Under Test (DUT) Identification Matrix

Complete this table for each physical device used during manual regression testing:

| Parameter | Device 1 (Primary Phone) | Device 2 (Secondary Phone) | Device 3 (Tablet / Large Screen) |
| :--- | :--- | :--- | :--- |
| **Device Model / Manufacturer** | | | |
| **Android OS Version** | | | |
| **Kernel Architecture (ABI)** | | | |
| **Memory Page Size (4 KB / 16 KB)** | | | |
| **Screen Resolution (Pixels)** | | | |
| **Screen Aspect Ratio** | | | |
| **Display Refresh Rate (Hz)** | | | |
| **Tester Name / Date** | | | |

---

## 2. Global Pre-Flight & System Checks

| Test ID | Verification Item | Expected Behavior | Result (`PASS` / `FAIL` / `NOT TESTED`) | Notes / Logcat Observations |
| :--- | :--- | :--- | :---: | :--- |
| **SYS-01** | **Clean Installation** | APK installs cleanly via `adb install` or package installer without security or parsing errors. | `NOT TESTED` | |
| **SYS-02** | **Cold Launch & Welcome** | App launches directly into `welcome_screen.tscn`. Animated coin logo and progress bar load without stutter. | `NOT TESTED` | |
| **SYS-03** | **Orientation Enforcement** | App strictly displays in Landscape mode. Rotating device does not invert or distort layout. | `NOT TESTED` | |
| **SYS-04** | **Main Menu & Sound** | Main menu loads. SFX toggle and Music toggle function correctly. Audio plays without crackling. | `NOT TESTED` | |
| **SYS-05** | **Fresh Save Progress** | Level Select displays only Stage 1 as AVAILABLE. Stages 2–10 display as LOCKED with lock icons. | `NOT TESTED` | |
| **SYS-06** | **Dev Bypass Inactive** | No developer bypass button appears in release build. Tapping locked Stage 2 shows locked modal. | `NOT TESTED` | |
| **SYS-07** | **Multitouch Touch Controls** | Left/Right and Jump buttons register simultaneously. Player can jump while running left or right. | `NOT TESTED` | |
| **SYS-08** | **Background & Resume** | Pressing Home and returning resumes gameplay without audio desync, black screens, or crash. | `NOT TESTED` | |
| **SYS-09** | **Screen Scaling (Expand)** | 16:9, 18:9, 20:9, and tablet aspect ratios scale cleanly via `canvas_items` expand mode. No HUD clipping. | `NOT TESTED` | |
| **SYS-10** | **App Exit & Re-launch** | Quitting app and relaunching preserves highest unlocked stage and completed level states. | `NOT TESTED` | |

---

## 3. Level-by-Level Manual Regression Protocol (Levels 1–10)

---

### LEVEL 1: "The Warm-Up" (World 1: Neon Ruins)

| Test Item | Verification Requirement | Result (`PASS` / `FAIL` / `NOT TESTED`) | Notes / Reproduction Steps |
| :--- | :--- | :---: | :--- |
| **1.1 Scene Load & HUD** | Level 1 loads smoothly. HUD displays `COINS: 0/10`, `WORLD 1 · STAGE 1`, and `PAUSE`. | `NOT TESTED` | |
| **1.2 Player Movement** | Left/Right touch buttons move player smoothly; Jump button executes crisp leaps. | `NOT TESTED` | |
| **1.3 Basic Platforms & Gaps** | Platform collisions solid; player does not fall through tiles or get snagged on edges. | `NOT TESTED` | |
| **1.4 Intro Traps & Spikes** | Initial spike traps give audible/visual feedback; landing on spikes causes instant death. | `NOT TESTED` | |
| **1.5 Coin Collection** | All 10 coins collectible; coin counter increments $1 \to 10$; chime audio triggers. | `NOT TESTED` | |
| **1.6 Death & Fast Retry** | Death triggers instant particle burst; 1-tap retry respawns player at start with zero input lockout. | `NOT TESTED` | |
| **1.7 Exit Gate Completion** | Exit gate unlocks only when 10/10 coins collected. Walking into gate triggers completion sound. | `NOT TESTED` | |
| **1.8 Progression & Save** | Level 1 marked COMPLETED in Level Select. Level 2 becomes AVAILABLE. Save file persists. | `NOT TESTED` | |

---

### LEVEL 2: "Trust Nothing" (World 1: Neon Ruins)

| Test Item | Verification Requirement | Result (`PASS` / `FAIL` / `NOT TESTED`) | Notes / Reproduction Steps |
| :--- | :--- | :---: | :--- |
| **2.1 Scene Load & HUD** | Level 2 loads. HUD displays `COINS: 0/10` and `WORLD 1 · STAGE 2`. | `NOT TESTED` | |
| **2.2 Fake Safe Platforms** | Visually enticing safe platforms drop or trigger traps when stepped on with clear $\ge 0.6\text{s}$ warning. | `NOT TESTED` | |
| **2.3 Crumbling Floor Mechanics**| Crumbling bridge sections shake before dropping; collision disables properly. | `NOT TESTED` | |
| **2.4 Ceiling Drop Hazards** | Falling blocks or ceiling hazards activate predictably with warning cues. | `NOT TESTED` | |
| **2.5 Coin Paths & Physics** | All 10 coins reachable through precision jumps; momentum physics deterministic. | `NOT TESTED` | |
| **2.6 Respawn Reliability** | Dying on crumbling floor resets platforms cleanly upon retry without ghost collision. | `NOT TESTED` | |
| **2.7 Exit Gate Trigger** | Reaching exit gate with 10 coins completes level; incomplete collection keeps gate locked. | `NOT TESTED` | |
| **2.8 Progression & Save** | Level 2 marked COMPLETED. Level 3 becomes AVAILABLE. Save persists on storage. | `NOT TESTED` | |

---

### LEVEL 3: "Fire & Fury" (World 1: Neon Ruins)

| Test Item | Verification Requirement | Result (`PASS` / `FAIL` / `NOT TESTED`) | Notes / Reproduction Steps |
| :--- | :--- | :---: | :--- |
| **3.1 Scene Load & HUD** | Level 3 loads. HUD displays `COINS: 0/10` and `WORLD 1 · STAGE 3`. | `NOT TESTED` | |
| **3.2 Inferno Gate Timing** | Fire gates cycle between dormant and active states. Spectral flame sound plays. | `NOT TESTED` | |
| **3.3 Flame Burst Hitboxes** | Flame hazard Area2D damages player accurately during burst; safe to traverse when dormant. | `NOT TESTED` | |
| **3.4 Precision Platforming** | Narrow platforms between fire jets require tight jump buffering and coyote time. | `NOT TESTED` | |
| **3.5 Coin Route Distribution** | 10 coins placed in timed flame corridors; player can collect all coins without unavoidable damage. | `NOT TESTED` | |
| **3.6 Death & Immediate Reset** | Death by fire resets all inferno timers synchronously to initial phase on retry. | `NOT TESTED` | |
| **3.7 Exit Gate Trigger** | Exit gate unlocks at 10 coins. Level completion triggers properly. | `NOT TESTED` | |
| **3.8 Progression & Save** | Level 3 marked COMPLETED. Level 4 becomes AVAILABLE. Save persists. | `NOT TESTED` | |

---

### LEVEL 4: "Crushing Silence" (World 1: Neon Ruins)

| Test Item | Verification Requirement | Result (`PASS` / `FAIL` / `NOT TESTED`) | Notes / Reproduction Steps |
| :--- | :--- | :---: | :--- |
| **4.1 Scene Load & HUD** | Level 4 loads. HUD displays `COINS: 0/10` and `WORLD 1 · STAGE 4`. | `NOT TESTED` | |
| **4.2 Moving Wall Mechanics** | Moving crusher walls advance and retract with heavy mechanical audio. | `NOT TESTED` | |
| **4.3 Compression & Crush Area**| Player crushed between wall and obstacle triggers death without falling through floor. | `NOT TESTED` | |
| **4.4 Tight Gap Traversal** | Player can slide/jump through moving wall gaps when timed correctly. | `NOT TESTED` | |
| **4.5 10-Coin Reachability** | All 10 coins positioned in compression zones; timing windows allow safe retrieval. | `NOT TESTED` | |
| **4.6 Death & Reset** | Death resets moving walls to starting offsets; no wall desynchronization occurs. | `NOT TESTED` | |
| **4.7 Exit Gate Trigger** | Reaching exit gate with 10 coins completes level. | `NOT TESTED` | |
| **4.8 Progression & Save** | Level 4 marked COMPLETED. Level 5 becomes AVAILABLE. Save persists. | `NOT TESTED` | |

---

### LEVEL 5: "The Final Betrayal" (World 1 Climax)

| Test Item | Verification Requirement | Result (`PASS` / `FAIL` / `NOT TESTED`) | Notes / Reproduction Steps |
| :--- | :--- | :---: | :--- |
| **5.1 Scene Load & HUD** | Level 5 loads. HUD displays `COINS: 0/10` and `WORLD 1 · STAGE 5`. | `NOT TESTED` | |
| **5.2 Fake Exit Gate Betrayal** | Decoy exit gate triggers surprise trap with audible laugh/trap audio. | `NOT TESTED` | |
| **5.3 Wall Spike Traps** | Wall spikes emerge from vertical surfaces when triggered by proximity. | `NOT TESTED` | |
| **5.4 Multi-Hazard Gauntlet** | Combination of crumbling floors, moving walls, and spikes tested simultaneously. | `NOT TESTED` | |
| **5.5 Coin Progression** | 10 coins scattered across treacherous path; all coins register cleanly. | `NOT TESTED` | |
| **5.6 Real Exit Gate** | Legitimate exit gate unlocks at 10 coins and triggers World 1 victory sequence. | `NOT TESTED` | |
| **5.7 World 2 Unlock** | Level 5 marked COMPLETED. Level 6 (World 2: The Haunted Hall) unlocks. | `NOT TESTED` | |
| **5.8 Save Persistence** | Quitting after Level 5 retains World 2 unlock status upon game reload. | `NOT TESTED` | |

---

### LEVEL 6: "Phantom's Curse" (World 2: The Haunted Hall)

| Test Item | Verification Requirement | Result (`PASS` / `FAIL` / `NOT TESTED`) | Notes / Reproduction Steps |
| :--- | :--- | :---: | :--- |
| **6.1 World 2 Atmosphere** | Gothic castle background, parallax towers, floating ghost sprites, and ground mist render. | `NOT TESTED` | |
| **6.2 Phantom Platform Shimmer**| Stone platforms emit visual shimmer warning before fading to spectral intangible state. | `NOT TESTED` | |
| **6.3 Collision Phasing** | Collision disables when platform is transparent; player falls through if lingering too long. | `NOT TESTED` | |
| **6.4 Platform Solidification** | Platform returns to solid state with clear opacity and collision re-enablement. | `NOT TESTED` | |
| **6.5 10-Coin Jump Arcs** | 10 coins distributed along jump trajectories between alternating phantom platforms. | `NOT TESTED` | |
| **6.6 Respawn Sync** | Respawn resets all phantom platform phase timers to starting synchrony. | `NOT TESTED` | |
| **6.7 Exit Gate Trigger** | Exit gate unlocks with 10 coins. Level completes. | `NOT TESTED` | |
| **6.8 Progression & Save** | Level 6 marked COMPLETED. Level 7 becomes AVAILABLE. | `NOT TESTED` | |

---

### LEVEL 7: "Hall of Illusions" (World 2: The Haunted Hall)

| Test Item | Verification Requirement | Result (`PASS` / `FAIL` / `NOT TESTED`) | Notes / Reproduction Steps |
| :--- | :--- | :---: | :--- |
| **7.1 Scene Load & HUD** | Level 7 loads. HUD displays `COINS: 0/10` and `WORLD 2 · STAGE 7`. | `NOT TESTED` | |
| **7.2 Multi-Tier Phantoms** | Multi-level hall with staggered phantom platforms with alternating phase cycles. | `NOT TESTED` | |
| **7.3 Input Lockout Fix Check** | Player dying on phantom platform respawns with full movement and jump control restored. | `NOT TESTED` | |
| **7.4 Platform Desync Fix Check**| Respawning does NOT leave platforms stuck in transparent or disabled collision states. | `NOT TESTED` | |
| **7.5 Coin Jump Timing** | All 10 coins collectable during solid phase windows. | `NOT TESTED` | |
| **7.6 Touch Response** | Touch controls remain responsive throughout multiple rapid deaths. | `NOT TESTED` | |
| **7.7 Summit Exit Gate** | Reaching top exit gate with 10 coins triggers completion. | `NOT TESTED` | |
| **7.8 Progression & Save** | Level 7 marked COMPLETED. Level 8 becomes AVAILABLE. | `NOT TESTED` | |

---

### LEVEL 8: "The Cursed Wind" (World 2: The Haunted Hall)

| Test Item | Verification Requirement | Result (`PASS` / `FAIL` / `NOT TESTED`) | Notes / Reproduction Steps |
| :--- | :--- | :---: | :--- |
| **8.1 Scene Load & Wind Audio** | Level 8 loads. Atmospheric wind howling loop plays. Flying wind streak particles render. | `NOT TESTED` | |
| **8.2 Cyclical Wind Gusts** | Wind blows with horizontal drift for 2.5s, followed by 2.0s of calm wind. | `NOT TESTED` | |
| **8.3 Shelter Zone Windbreaks** | Standing behind gothic stone pillars/arches completely negates wind push force. | `NOT TESTED` | |
| **8.4 Jump Trajectory Balance** | Precision jumps across wind-swept chasms are fair and reachable during calm periods. | `NOT TESTED` | |
| **8.5 10-Coin Distribution** | 10 coins placed across gusts; coins do not blow away or drift out of reach. | `NOT TESTED` | |
| **8.6 Pit Hazards & Respawn** | Falling into wind chasm causes instant death; respawn resets wind cycle cleanly. | `NOT TESTED` | |
| **8.7 Exit Gate Trigger** | Exit gate on final sanctuary platform unlocks at 10 coins and triggers complete. | `NOT TESTED` | |
| **8.8 Progression & Save** | Level 8 marked COMPLETED. Level 9 becomes AVAILABLE. | `NOT TESTED` | |

---

### LEVEL 9: "Chains of the Damned" (World 2: The Haunted Hall)

| Test Item | Verification Requirement | Result (`PASS` / `FAIL` / `NOT TESTED`) | Notes / Reproduction Steps |
| :--- | :--- | :---: | :--- |
| **9.1 HUD Layout Verification** | Coin Counter on left, Level Title center, Pause button on top-right (No swapped buttons). | `NOT TESTED` | |
| **9.2 Pendulum Chain Motion** | 5 massive ghost chains swing with smooth harmonic motion $\theta(t) = \theta_{\max} \sin(\omega t)$. | `NOT TESTED` | |
| **9.3 Chain Dual-Zone Hitbox** | Upper anchor mount allows pass-through; heavy bottom weight and lower 40% are lethal. | `NOT TESTED` | |
| **9.4 Sanctuary Platforms** | Safe resting platforms between chain arcs allow timing observation. | `NOT TESTED` | |
| **9.5 10-Coin Swing Precision** | 10 coins placed inside pendulum swing paths; collecting them requires rhythmic timing. | `NOT TESTED` | |
| **9.6 Chain Metallic Sound** | Chains emit metallic rattle and whoosh audio during swing peak. | `NOT TESTED` | |
| **9.7 Summit Exit Gate** | Final exit gate resting flush on summit sanctuary unlocks at 10 coins. | `NOT TESTED` | |
| **9.8 Progression & Save** | Level 9 marked COMPLETED. Level 10 (Boss Stage) becomes AVAILABLE. | `NOT TESTED` | |

---

### LEVEL 10: "Haunted Survival" (World 2 Climax / Boss Stage)

| Test Item | Verification Requirement | Result (`PASS` / `FAIL` / `NOT TESTED`) | Notes / Reproduction Steps |
| :--- | :--- | :---: | :--- |
| **10.1 Fixed 960x540 Arena** | Camera is strictly fixed to $960 \times 540$ screen boundaries (No scrolling or camera jitter). | `NOT TESTED` | |
| **10.2 Boss Intro Overlay** | "SURVIVE FOR 1 MINUTE!" intro overlay displays; player movement locked during intro. | `NOT TESTED` | |
| **10.3 60s Survival Timer** | Survival timer counts down continuously in HUD from $60.0\text{s} \to 0.0\text{s}$. | `NOT TESTED` | |
| **10.4 10-Round Schedule HUD** | HUD displays round badge updating every 6s: `[R1/10]` through `[R10/10]`. | `NOT TESTED` | |
| **10.5 Dynamic Coin Spawns** | Exactly 1 coin spawns per 6-second round (10 total coins spawned across attempt). | `NOT TESTED` | |
| **10.6 Anti-Camping Platform Sweep**| Lingering on any platform is punished within 5–6s; player forced to traverse P1–P5. | `NOT TESTED` | |
| **10.7 Multi-Chain Attacks** | 5 ceiling attack mounts trigger single, dual, or triple chain swings with safe corridors. | `NOT TESTED` | |
| **10.8 Fairness Guarantee** | Every hazard wave provides $\ge 0.6\text{s}$ warning and guarantees $\ge 2$ safe platforms. | `NOT TESTED` | |
| **10.9 Final 10s Countdown** | Alert banner displays at 50s; large pulsing numbers count down 5, 4, 3, 2, 1. | `NOT TESTED` | |
| **10.10 Boss Victory & Save** | At $t = 60.0\text{s}$, Boss Victory Overlay triggers ("WORLD 2 COMPLETE!"); Level 11 unlocks. | `NOT TESTED` | |

---

## 4. Device Lifecycle, Scaling & Diagnostics Checklist

| Test ID | Test Scenario | Expected Result | Result | Observations / Notes |
| :--- | :--- | :--- | :---: | :--- |
| **LIF-01** | **Incoming Call / Interruption** | Game pauses automatically when phone call banner appears; resumes smoothly. | `NOT TESTED` | |
| **LIF-02** | **Lock Screen / Wake** | Locking device and waking returns to paused or active game without crash. | `NOT TESTED` | |
| **LIF-03** | **Rapid Touch Spamming** | Tapping all 3 touch buttons simultaneously at 10 Hz causes no input thread locks. | `NOT TESTED` | |
| **LIF-04** | **120 Hz / High Refresh Rate** | Game physics tick at fixed 60 Hz (`_physics_process`); rendering interpolates smoothly. | `NOT TESTED` | |
| **LIF-05** | **Tablet Aspect Ratio (4:3 / 16:10)**| Viewport expands vertically/horizontally; buttons stay within comfortable reach. | `NOT TESTED` | |
| **LIF-06** | **Low-End SoC Thermal Check** | Running Level 10 for 15 minutes causes no excessive thermal throttling or stutter. | `NOT TESTED` | |
| **LIF-07** | **Logcat Error Audit** | `adb logcat *:E` exhibits zero Godot engine error panics, leaks, or ANR traces. | `NOT TESTED` | |

---

## 5. QA Tester Sign-Off Sheet

```
+------------------------------------------------------------------------------------+
|                         REGRESSION TESTING VERIFICATION SIGN-OFF                   |
+------------------------------------------------------------------------------------+
| Lead QA Tester:        _______________________________                             |
| Test Execution Date:   _______________________________                             |
| Physical Device Used:  _______________________________ (Android API: ___)          |
| Total Levels Passed:   ___ / 10                                                    |
| Release Recommendation: [ ] APPROVED FOR GOOGLE PLAY CLOSED TESTING                |
|                         [ ] REJECTED - CRITICAL DEFECTS IDENTIFIED                 |
+------------------------------------------------------------------------------------+
```
