# RETRO RAGE ARCADE: LEVEL 18 EXTREME DIFFICULTY REWORK
## World 4: Final Hell — Stage 3: THE RISING ABYSS

**Document Version:** 2.0.0  
**Target Engine:** Godot 4.7.2-stable (Win64 / Android API 36)  
**Branch:** `migration/android-api36-godot47`  
**Test Suite Status:** 3,321 Passed / 0 Failed  

---

## 1. Executive Summary & Audit: Why Original Level 18 Was Too Easy

Following hands-on playtesting, the initial implementation of **Level 18 — THE RISING ABYSS** failed to meet the required difficulty benchmark. While Level 17 ("THE INFERNAL DECEPTION") provided an intense, deceptive challenge, initial Level 18 allowed players to clear the stage casually on their first or second attempt. 

A thorough audit identified the root causes:

1. **Sluggish, Non-Threatening Hazard Timeline:**
   - The original Rising Abyss operated on a prolonged **75.0-second** timeline with sluggish ascent velocities ($13.48\text{ px/s}$ to $19.00\text{ px/s}$).
   - The hazard ceiling capped at $Y = -650.0$, far below the exit plateau ($Y = -840.0$), completely abandoning all pressure in the climax.
   - Competent players outran the abyss by $300\text{px}$ to $500\text{px}$, turning a life-or-death vertical climb into a casual platformer.

2. **Excessive Platform Safety Margins:**
   - Platform widths ranged from $70\text{px}$ to $100\text{px}$ ($Ground1$ was $120\text{px}$, $ExitPlatform$ was $120\text{px}$, $Platform6$ was $100\text{px}$, $Platform9$ was $90\text{px}$).
   - Landing tolerances were exceptionally generous, forgiving inaccurate jump arcs and clumsy landings.

3. **Gentle Horizontal Spacing:**
   - Edge-to-edge gaps between platforms averaged only $30\text{px}$ to $55\text{px}$, well below the player's flat horizontal reach limit of $196.17\text{px}$. Jumps required minimal forward momentum or precision.

4. **Permissive Hazard Windows:**
   - Hell Runes featured long warning phases ($0.45\text{s}$ to $0.50\text{s}$) and lazy cooldown periods ($1.50\text{s}$ to $1.80\text{s}$), allowing players to wait out cycles safely.
   - Infernal Energy Gates offered overly wide passage intervals ($1.70\text{s}$ to $1.80\text{s}$ inactive), eliminating timing urgency.
   - Disappearing Hell Platforms gave players $0.85\text{s}$ to $0.90\text{s}$ of shake time before vanishing, granting ample time to hesitate.

5. **Weak Finale (Section D):**
   - Section D featured only a single vertical gate and widely spaced perches, lacking the compounding pressure expected of a penultimate World 4 gauntlet.

---

## 2. Extreme Difficulty Rework Philosophy

The rework transforms Level 18 into an **extreme, pulse-pounding difficulty spike** that demands precision, forward momentum, route anticipation, and continuous execution under severe time pressure, while strictly adhering to deterministic kinematics and fair design:

1. **Relentless Environmental Pressure:**
   - The player must move constantly. Pausing to rest or camp guarantees incineration.
2. **Precision Landings:**
   - Landing surfaces have been contracted to razor-thin perches ($48\text{px}$ to $60\text{px}$). Overshooting or undershooting results in instant death.
3. **Commitment Jumps:**
   - Gaps have been widened to $70\text{px}$ to $100\text{px}$ with steep vertical rises ($35\text{px}$ to $70\text{px}$), requiring full-speed takeoffs and apex control.
4. **Interleaved Hazards:**
   - Rune bursts, energy lasers, and collapsing footholds operate in tight synchronization. 
5. **Deterministic & Fair:**
   - Every jump is mathematically verified against the engine's jump curve. No blind leaps, no invisible geometry, and no frame-perfect impossibility.

---

## 3. Platforming Layout Rework

### A. Kinematics Reference
- **Horizontal Move Speed ($v_x$):** $240.0\text{ px/s}$
- **Jump Impulse ($v_0$):** $-470.0\text{ px/s}$
- **Gravity ($g$):** $1150.0\text{ px/s}^2$
- **Apex Time ($t_{apex}$):** $0.4087\text{ s}$
- **Max Jump Height ($H_{max}$):** $96.04\text{ px}$
- **Flat Flight Time ($t_{flat}$):** $0.8174\text{ s}$
- **Flat Reach ($R_{flat}$):** $196.17\text{ px}$
- **Player Hitbox:** $20\text{px} \times 28\text{px}$ (Origin bottom-center)

### B. Four-Section Layout & Dimensional Overhaul

#### Section A — The Awakening Pit ($Y = 440 \to Y = 200$, $X = 60 \to 720$)
- **Ground1:** Reduced from $120\text{px} \to 80\text{px}$ at $(100, 440)$.
- **Platform1:** Reduced to $50\text{px}$ at $(240, 410)$. Gap: $80.0\text{px}$, Step: $+30.0\text{px}$.
- **Platform2:** Reduced to $50\text{px}$ at $(370, 375)$. Hell Rune active. Gap: $80.0\text{px}$, Step: $+35.0\text{px}$.
- **Platform3:** Reduced to $50\text{px}$ at $(500, 340)$. Gap: $80.0\text{px}$, Step: $+35.0\text{px}$.
- **Platform4:** Reduced from $90\text{px} \to 50\text{px}$ at $(630, 305)$. Gap: $80.0\text{px}$, Step: $+35.0\text{px}$.
- **Platform5:** Reduced to $50\text{px}$ at $(750, 270)$. Gap: $70.0\text{px}$, Step: $+35.0\text{px}$.
- **Platform6:** Reduced from $100\text{px} \to 60\text{px}$ at $(865, 235)$. Gap: $60.0\text{px}$, Step: $+35.0\text{px}$.

#### Section B — The Sinking Path ($Y = 200 \to Y = -120$, $X = 865 \to 80$)
- Traverses back leftwards across a decaying zig-zag path over the rising void.
- **DisappearingPlatform1:** Narrowed to $50\text{px}$ at $(750, 190)$. Shake: $0.55\text{s}$. Gap: $60.0\text{px}$, Step: $+45.0\text{px}$.
- **Platform7:** Narrowed to $48\text{px}$ at $(625, 150)$. Hell Rune active. Gap: $76.0\text{px}$, Step: $+40.0\text{px}$.
- **DisappearingPlatform2:** Narrowed to $50\text{px}$ at $(495, 105)$. Shake: $0.50\text{s}$. Gap: $81.0\text{px}$, Step: $+45.0\text{px}$.
- **Platform8:** Narrowed to $48\text{px}$ at $(370, 60)$. Hell Rune active. Gap: $76.0\text{px}$, Step: $+45.0\text{px}$.
- **DisappearingPlatform3:** Narrowed to $50\text{px}$ at $(240, 15)$. Shake: $0.50\text{s}$. Gap: $81.0\text{px}$, Step: $+45.0\text{px}$.
- **Platform9:** Reduced from $90\text{px} \to 60\text{px}$ at $(115, -25)$. Gap: $70.0\text{px}$, Step: $+40.0\text{px}$.

#### Section C — The Infernal Climb ($Y = -120 \to Y = -520$, $X = 80 \to 1080$)
- Long rightward climb under severe vertical gate gating and narrow platforms.
- **Platform10:** Narrowed to $50\text{px}$ at $(245, -70)$. Gap: $75.0\text{px}$, Step: $+45.0\text{px}$.
- **Platform11:** Narrowed to $50\text{px}$ at $(375, -120)$. Hell Rune active. Gap: $80.0\text{px}$, Step: $+50.0\text{px}$.
- **Platform12:** Narrowed to $50\text{px}$ at $(510, -170)$. Gap: $85.0\text{px}$, Step: $+50.0\text{px}$.
- **DisappearingPlatform4:** Narrowed to $50\text{px}$ at $(650, -215)$. Shake: $0.55\text{s}$. Gap: $90.0\text{px}$, Step: $+45.0\text{px}$.
- **Platform13:** Narrowed to $50\text{px}$ at $(785, -265)$. Gap: $85.0\text{px}$, Step: $+50.0\text{px}$.
- **Platform14:** Narrowed to $55\text{px}$ at $(920, -315)$. Stationed underneath horizontal beam $EnergyGate\_C2$. Headroom: $21.0\text{px}$. Gap: $82.5\text{px}$, Step: $+50.0\text{px}$.
- **Platform15:** Reduced from $85\text{px} \to 60\text{px}$ at $(1055, -365)$. Hell Rune active. Gap: $77.5\text{px}$, Step: $+50.0\text{px}$.

#### Section D — The Last Ascent ($Y = -520 \to Y = -850$, $X = 1080 \to 50$)
- Extreme climax featuring rapid disappearing ledges, dual energy gates, and a lethal deceptive route.
- **DisappearingPlatform5:** Narrowed to $50\text{px}$ at $(930, -415)$. Shake: $0.50\text{s}$. Gap: $70.0\text{px}$, Step: $+50.0\text{px}$.
- **Platform16:** Narrowed to $50\text{px}$ at $(795, -465)$. Hell Rune active. Gap: $85.0\text{px}$, Step: $+50.0\text{px}$.
- **DisappearingPlatform6:** Narrowed to $50\text{px}$ at $(660, -515)$. Shake: $0.50\text{s}$. Gap: $85.0\text{px}$, Step: $+50.0\text{px}$.
- **Platform17:** Narrowed to $50\text{px}$ at $(525, -565)$. Gap: $85.0\text{px}$, Step: $+50.0\text{px}$.
- **The Deceptive Fork:**
  - *Trap Route:* $Platform18\_Trap$ at $(380, -600)$ is stationary and inviting, but harbors $HellRune\_Trap$, which erupts violently as the player lands.
  - *True Route:* $DisappearingPlatform7$ at $(375, -625)$ requires an airborne apex leap ($Gap = 100.0\text{px}$, $Step = +60.0\text{px}$, $Shake = 0.50\text{s}$).
- **Dual Energy Gate Hurdle:** As the player clears $DisappearingPlatform7$, they must clear both $EnergyGate\_D1\_Vertical$ at $X = 450$ and the newly installed $EnergyGate\_D2\_Vertical$ at $X = 300$.
- **Platform19_Summit:** Narrowed to $50\text{px}$ at $(235, -680)$. Gap: $90.0\text{px}$, Step: $+55.0\text{px}$.
- **ExitPlatform:** Reduced from $120\text{px} \to 80\text{px}$ at $(85, -750)$. Gap: $85.0\text{px}$, Step: $+70.0\text{px}$.

---

## 4. The Rising Abyss: Relentless Environmental Surge

The Rising Abyss hazard ([`scripts/coin_hell/rising_abyss.gd`](file:///c:/AntiGravity/Games/rage_bait/scripts/coin_hell/rising_abyss.gd)) has been re-engineered from the ground up:

### A. Accelerated 42.0-Second Timeline
| Phase | Duration | Surface Y Movement | Ascent Rate | Gameplay Impact |
| :--- | :---: | :---: | :---: | :--- |
| **1. Warning Phase** | $0.0\text{s} - 2.0\text{s}$ ($2.0\text{s}$) | $520.0 \to 520.0$ | $0.00\text{ px/s}$ | Brief auditory alarm at $t = 0.5\text{s}$; player must launch immediately. |
| **2. Awakening Rise** | $2.0\text{s} - 9.0\text{s}$ ($7.0\text{s}$) | $520.0 \to 300.0$ | **$31.43\text{ px/s}$** | Submerges $Ground1$ and lower Section A if player hesitates. |
| **3. Sinking Surge** | $9.0\text{s} - 18.0\text{s}$ ($9.0\text{s}$) | $300.0 \to 20.0$ | **$31.11\text{ px/s}$** | Obliterates Section B platforms as player jumps across collapsing ledges. |
| **4. Infernal Climb** | $18.0\text{s} - 29.0\text{s}$ ($11.0\text{s}$) | $20.0 \to -360.0$ | **$34.55\text{ px/s}$** | Highest velocity surge; floods Section C under laser gates. |
| **5. Final Cataclysm**| $29.0\text{s} - 42.0\text{s}$ ($13.0\text{s}$) | $-360.0 \to -720.0$| **$27.69\text{ px/s}$** | Cataclysmic surge submerging Section D up to the summit steps. |
| **Ceiling Clamp** | $t \ge 42.0\text{s}$ | Fixed at $-720.0$ | $0.00\text{ px/s}$ | Submerges all lower platforms permanently; $82\text{px}$ below exit top. |

### B. Mechanical Guarantee & Fair Exit Access
- $ExitPlatform$ sits at $Y = -750.0$ (top surface $Y = -802.0$), and $ExitGate$ sits at $Y = -850.0$.
- Because the abyss ceiling is locked at $Y = -720.0$, the exit gate is never blocked by lava, guaranteeing that a player who conquers the platforming gauntlet can always complete the level.

---

## 5. Hazard Configuration & Synchronization

### A. Hell Runes
- **Warning Phase:** Reduced to $0.30\text{s} - 0.38\text{s}$ (vivid ground warning pulse).
- **Active Eruption:** $0.65\text{s}$ lethal flame pillar.
- **Cooldown:** Compressed to $0.95\text{s} - 1.10\text{s}$ (down from $1.80\text{s}$). Waiting for a second cycle is perilous due to the rising lava.

### B. Infernal Energy Gates
- **Warning Flash:** $0.50\text{s} - 0.55\text{s}$.
- **Active Laser Beam:** $0.80\text{s} - 0.85\text{s}$ lethal beam.
- **Safe Aperture Window:** Tightened to $1.10\text{s} - 1.15\text{s}$ (down from $1.80\text{s}$).
- **Section D Gate Interleaving:** Two vertical gates ($EnergyGate\_D1$ at $X = 450$, $EnergyGate\_D2$ at $X = 300$) create alternating rhythmic laser hurdles across the final gap sequence.

### C. Disappearing Hell Platforms
- **Shake Duration:** Cut down to $0.50\text{s} - 0.55\text{s}$ (down from $0.90\text{s}$). Players cannot pause or second-guess on collapsing surfaces.
- **Vanish Duration:** $1.80\text{s} - 2.00\text{s}$ intangibility before reappearing.

---

## 6. Coin Positioning Audit (10/10 Distinct & Reachable)

All 10 coins have been recalibrated to reward precise jump trajectories and enforce high-risk path execution:

| Coin | Target Location | Coordinates | Risk Profile / Challenge |
| :---: | :--- | :---: | :--- |
| **Coin 1** | Section A: Gap $Platform1 \to Platform2$ | $(280, 310)$ | Requires committing to a high jump arc over the gap. |
| **Coin 2** | Section A: Gap $Platform3 \to Platform4$ | $(545, 235)$ | Placed at apex of jump above ascending lava line. |
| **Coin 3** | Section B: $DisappearingPlatform1$ Entry | $(692, 75)$ | Floating directly over the void chasm. |
| **Coin 4** | Section B: $DisappearingPlatform2 \to Platform8$ | $(437, -25)$ | Demands forward momentum jump between crumbling ledges. |
| **Coin 5** | Section B: Over $DisappearingPlatform3$ | $(245, -80)$ | Positioned above quick-decaying platform ($0.50\text{s}$ shake). |
| **Coin 6** | Section C: $EnergyGate\_C1$ Aperture | $(448, -225)$ | Timed jump directly through the laser aperture. |
| **Coin 7** | Section C: Gap $Platform14 \to Platform15$ | $(992, -390)$ | Long commitment leap under horizontal laser beam. |
| **Coin 8** | Section D: Over $DisappearingPlatform5$ | $(935, -510)$ | Apex placement above collapsing foothold. |
| **Coin 9** | Section D: Above $Platform17$ | $(530, -665)$ | High apex placement before the deceptive fork. |
| **Coin 10**| Section D: Over $DisappearingPlatform7$ (True Route)| $(380, -720)$ | Summit coin positioned strictly on the true airborne route. |

---

## 7. Automated Test Results

The full headless Godot test suite was executed via console:
```powershell
& "C:\Users\hp\godot\Godot_v4.7.2-stable_win64_console.exe" --headless "res://scenes/tests/test_runner.tscn"
```

### Verified Coverage
- **Total Assertions Executed:** 3,321
- **Total Assertions Passed:** 3,321
- **Total Assertions Failed:** 0
- **Level 18 Dedicated Assertions:**
  - `test_level_18_rising_abyss_hazard_mechanics_and_timeline`: **PASS** (42.0s timeline, 5 phases, -720.0 cap).
  - `test_level_18_rising_abyss_layout_and_coins`: **PASS** (28 platforms, 4 energy gates, 10 coins, exit gate at $Y = -850$).
  - `test_level_18_jump_physics_and_kinematic_reachability`: **PASS** (all 26 sequential jumps strictly verified within kinematic limits, Section C headroom, Section D trap & dual gates).
  - `test_level_18_lifecycle_death_retry_revive_resets`: **PASS** (death overlay, full restart reset, safe revive anchor at $(120, 350)$, 1-revive limit).
  - `test_level_18_completion_and_progression_advancement`: **PASS** (10/10 coin unlock, completion save, Level 19 progression advance, Levels 19 & 20 remain planned/locked).
- **Regression Invariance:** Levels 1–17 test suites executed and passed with 100% success.
