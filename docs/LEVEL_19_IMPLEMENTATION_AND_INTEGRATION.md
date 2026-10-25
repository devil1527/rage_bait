# RETRO RAGE ARCADE: LEVEL 19 IMPLEMENTATION & ARCHITECTURE
## World 4: Final Hell — Stage 4: THE SOUL GAUNTLET
### Controls Parity & Difficulty Rebalance (Target ~60%)

**Document Version:** 1.1.0  
**Target Engine:** Godot 4.7.2-stable (Win64 / Android API 36)  
**Branch:** `migration/android-api36-godot47`  
**Test Suite Status:** 3,550 Passed / 0 Failed  

---

## 1. Executive Summary & Level Identity

**Level 19 — THE SOUL GAUNTLET** is the penultimate trial of **RETRO RAGE ARCADE (World 4: Final Hell)**. Designed to test precision platforming, timing, and mastery of multiple hazards, Level 19 introduces **a chained precision gauntlet where landing position and hazard timing determine progression**.

Following developer feedback, two critical areas have been corrected and verified:
1. **Full Controls Parity with Reference Levels (16, 17, 18):**
   - Corrected all three on-screen controls (`LeftBtn`, `RightBtn`, and `JumpBtn`) to match the exact visual dimensions, scaling, touch margins, and screen-edge positioning established in Levels 16–18.
2. **Substantial Difficulty Rebalance (~70% $\to$ ~60%):**
   - Rebalanced from an overly punishing ~70% down to an achievable, learnable ~60% challenge. Widened narrow landing surfaces from $48\text{px} - 55\text{px}$ to $58\text{px} - 90\text{px}$, expanded Hell Rune warning reaction windows from $0.30\text{s} - 0.32\text{s}$ to $0.48\text{s}$, increased collapsing platform stability from $0.48\text{s} - 0.50\text{s}$ to $0.70\text{s} - 0.75\text{s}$, and opened Infernal Energy Gate safe transit windows from $1.05\text{s} - 1.15\text{s}$ to $1.55\text{s} - 1.65\text{s}$.

---

## 2. On-Screen Touch Controls Parity

Inspection of Levels 16, 17, and 18 identified the exact layout, dimensions, touch areas, and margins standard in the project:

| Control | Property | Previous Level 19 (Erroneous) | Standard in Levels 16–18 | Corrected Level 19 |
| :--- | :--- | :--- | :--- | :--- |
| **LeftBtn** | Visual Size | $80 \times 80\text{px}$ | $104 \times 104\text{px}$ | **$104 \times 104\text{px}$** |
| | Offsets (`L, T, R, B`) | `(24, -104, 104, -24)` | `(24, -128, 128, -24)` | **`(24, -128, 128, -24)`** |
| | `touch_margin` | $0.0\text{px}$ (default) | $8.0\text{px}$ | **$8.0\text{px}$** |
| | Effective Touch Box | $80 \times 80\text{px}$ | $120 \times 120\text{px}$ | **$120 \times 120\text{px}$** |
| **RightBtn** | Visual Size | $80 \times 80\text{px}$ | $104 \times 104\text{px}$ | **$104 \times 104\text{px}$** |
| | Offsets (`L, T, R, B`) | `(124, -104, 204, -24)` | `(144, -128, 248, -24)` | **`(144, -128, 248, -24)`** |
| | `touch_margin` | $0.0\text{px}$ (default) | $8.0\text{px}$ | **$8.0\text{px}$** |
| | Effective Touch Box | $80 \times 80\text{px}$ | $120 \times 120\text{px}$ | **$120 \times 120\text{px}$** |
| **Button Gap**| Left to Right Spacing | $20\text{px}$ (small icons) | $16\text{px}$ (`144 - 128`) | **$16\text{px}$ (`144 - 128`)** |
| **JumpBtn** | Visual Size | $80 \times 80\text{px}$ | $124 \times 124\text{px}$ | **$124 \times 124\text{px}$** |
| | Offsets (`L, T, R, B`) | `(-104, -104, -24, -24)`| `(-148, -148, -24, -24)`| **`(-148, -148, -24, -24)`** |
| | `touch_margin` | $0.0\text{px}$ (default) | $16.0\text{px}$ | **$16.0\text{px}$** |
| | Effective Touch Box | $80 \times 80\text{px}$ | $156 \times 156\text{px}$ | **$156 \times 156\text{px}$** |

### Ergonomics & Mobile Usability Verification
- **Left/Right Separation:** With visual size $104\text{px}$ and positions `Left: 24..128` and `Right: 144..248`, the physical separation between buttons is exactly $16\text{px}$, preventing inadvertent multi-touches while preserving smooth finger rolling.
- **Jump Hitbox:** $124 \times 124\text{px}$ visual size with `touch_margin = 16.0` creates a massive $156 \times 156\text{px}$ effective responsive hit area anchored comfortably in the bottom-right corner for landscape thumbs.
- **Safe Area Anchoring:** Both control clusters sit $24\text{px}$ above screen bottom, respecting Android navigation bars and rounded corner displays.

---

## 3. Difficulty Rebalance Breakdown (70% $\to$ 60%)

### A. Platform Widths & Landing Tolerance
Landing surfaces were substantially widened across every section:
- `Ground1`: $70\text{px} \to 90\text{px}$ (+29% starting runway)
- `Platform1`: $50\text{px} \to 70\text{px}$ (+40% landing area)
- `Platform2`, `Platform3`, `Platform4`: $50\text{px} \to 64\text{px}$ (+28% landing area)
- `DisappearingPlatform1`: $48\text{px} \to 60\text{px}$ (+25%)
- `Platform5`: $48\text{px} \to 64\text{px}$ (+33%)
- `DisappearingPlatform2`, `DisappearingPlatform3`: $48\text{px} \to 58\text{px}$ (+21%)
- `Platform6`: $55\text{px} \to 70\text{px}$ (+27%)
- `Platform7`, `Platform8`: $50\text{px} \to 64\text{px}$ (+28%)
- `DisappearingPlatform4`: $48\text{px} \to 60\text{px}$ (+25%)
- `Platform9`: $52\text{px} \to 66\text{px}$ (+27%)
- `DisappearingPlatform5`: $48\text{px} \to 58\text{px}$ (+21%)
- `Platform10`: $50\text{px} \to 64\text{px}$ (+28%)
- `Platform11_Trap`: $65\text{px} \to 70\text{px}$
- `DisappearingPlatform6`, `DisappearingPlatform7`: $48\text{px} \to 60\text{px}$ (+25%)
- `ExitPlatform`: $80\text{px} \to 90\text{px}$ (+12.5%)

### B. Hazard Reaction Windows & Durations
- **Standard Hell Runes (`HellRune_A1`, `A2`, `B1`, `B2`, `C1`, `C2`, `D1`):**
  - Warning duration: increased from $0.30\text{s} - 0.32\text{s} \to 0.48\text{s}$ (+50% to +60% reaction window).
  - Active lethal duration: shortened from $0.65\text{s} \to 0.60\text{s}$.
  - Cooldown: extended from $0.95\text{s} - 1.0\text{s} \to 1.35\text{s}$ (+35% recovery time).
- **Deceptive Trap Rune (`HellRune_Trap`):**
  - Warning duration: increased from $0.22\text{s} \to 0.35\text{s}$ (+59%), allowing alert players to recognize the trap before dying.
- **Infernal Energy Gates (`EnergyGate_C1`, `C2`, `C3`, `D1`, `D2`):**
  - Inactive (safe transit) durations: lengthened from $1.05\text{s} - 1.15\text{s} \to 1.55\text{s} - 1.65\text{s}$ (+40% to +50% larger passage window).
  - Active lethal durations: reduced from $0.80\text{s} - 0.85\text{s} \to 0.70\text{s} - 0.75\text{s}$.
- **Disappearing Hell Platforms (`DisappearingPlatform1` through `7`):**
  - Shake warning duration: increased from $0.48\text{s} - 0.50\text{s} \to 0.70\text{s} - 0.75\text{s}$ (+40% to +56% longer standing stability before collapse).

---

## 4. Kinematic & Jump Reachability Verification Table

All jumps verified against exact Godot CharacterBody2D physics parameters:
- $v_x = 240.0\text{ px/s}$
- $v_0 = -470.0\text{ px/s}$
- $g = 1150.0\text{ px/s}^2$
- $R_{flat} = 196.17\text{ px}$
- $H_{max} = 96.04\text{ px}$

| Jump # | From Platform | To Platform | Platform Gap | Upward Step | Max Reach | Kinematic Margin | Status |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **1** | `Ground1` | `Platform1` | $60.0\text{px}$ | $+30.0\text{px}$ | $179.4\text{px}$ | $+119.4\text{px}$ | **PASS** |
| **2** | `Platform1` | `Platform2` | $73.0\text{px}$ | $+35.0\text{px}$ | $176.3\text{px}$ | $+103.3\text{px}$ | **PASS** |
| **3** | `Platform2` | `Platform3` | $71.0\text{px}$ | $+35.0\text{px}$ | $176.3\text{px}$ | $+105.3\text{px}$ | **PASS** |
| **4** | `Platform3` | `Platform4` | $71.0\text{px}$ | $+35.0\text{px}$ | $176.3\text{px}$ | $+105.3\text{px}$ | **PASS** |
| **5** | `Platform4` | `DisappearingPlatform1` | $63.0\text{px}$ | $+35.0\text{px}$ | $176.3\text{px}$ | $+113.3\text{px}$ | **PASS** |
| **6** | `DisappearingPlatform1`| `Platform5` | $63.0\text{px}$ | $+35.0\text{px}$ | $176.3\text{px}$ | $+113.3\text{px}$ | **PASS** |
| **7** | `Platform5` | `DisappearingPlatform2` | $63.0\text{px}$ | $+30.0\text{px}$ | $179.4\text{px}$ | $+116.4\text{px}$ | **PASS** |
| **8** | `DisappearingPlatform2`| `DisappearingPlatform3` | $60.0\text{px}$ | $+30.0\text{px}$ | $179.4\text{px}$ | $+119.4\text{px}$ | **PASS** |
| **9** | `DisappearingPlatform3`| `Platform6` | $65.0\text{px}$ | $+30.0\text{px}$ | $179.4\text{px}$ | $+114.4\text{px}$ | **PASS** |
| **10**| `Platform6` | `Platform7` | $63.0\text{px}$ | $+30.0\text{px}$ | $179.4\text{px}$ | $+116.4\text{px}$ | **PASS** |
| **11**| `Platform7` | `Platform8` | $66.0\text{px}$ | $+30.0\text{px}$ | $179.4\text{px}$ | $+113.4\text{px}$ | **PASS** |
| **12**| `Platform8` | `DisappearingPlatform4` | $63.0\text{px}$ | $+30.0\text{px}$ | $179.4\text{px}$ | $+116.4\text{px}$ | **PASS** |
| **13**| `DisappearingPlatform4`| `Platform9` | $67.0\text{px}$ | $+35.0\text{px}$ | $176.3\text{px}$ | $+109.3\text{px}$ | **PASS** |
| **14**| `Platform9` | `DisappearingPlatform5` | $62.0\text{px}$ | $+35.0\text{px}$ | $176.3\text{px}$ | $+114.3\text{px}$ | **PASS** |
| **15**| `DisappearingPlatform5`| `Platform10` | $63.0\text{px}$ | $+40.0\text{px}$ | $173.0\text{px}$ | $+110.0\text{px}$ | **PASS** |
| **16**| `Platform10` | `DisappearingPlatform6` | $53.0\text{px}$ | $+55.0\text{px}$ | $162.2\text{px}$ | $+109.2\text{px}$ | **PASS** |
| **17**| `DisappearingPlatform6`| `DisappearingPlatform7` | $56.0\text{px}$ | $+40.0\text{px}$ | $173.0\text{px}$ | $+117.0\text{px}$ | **PASS** |
| **18**| `DisappearingPlatform7`| `ExitPlatform` | $41.0\text{px}$ | $+30.0\text{px}$ | $179.4\text{px}$ | $+138.4\text{px}$ | **PASS** |

---

## 5. Ten Collectible Coins & Exit Verification

All 10 coins remain strictly reachable and required to unlock the Infernal Exit Gate:
- `Coin 1` at $(290, 260)$: Mid-air jump arc from `Platform1` to `Platform2`.
- `Coin 2` at $(560, 195)$: Jump arc from `Platform3` to `Platform4`.
- `Coin 3` at $(690, 150)$: High leap onto `DisappearingPlatform1`.
- `Coin 4` at $(940, 90)$: Apex of Jump 7 onto `DisappearingPlatform2`.
- `Coin 5` at $(1190, 35)$: Jump arc from `DisappearingPlatform3` to `Platform6`.
- `Coin 6` at $(1450, -40)$: Leap through `Platform7` to `Platform8`.
- `Coin 7` at $(1710, -110)$: Centered in the passage aperture of `EnergyGate_C3_Vertical`.
- `Coin 8` at $(1965, -185)$: Centered in the aperture of `EnergyGate_D1_Vertical`.
- `Coin 9` at $(2080, -240)$: Apex leap to the high True Route (`DisappearingPlatform6`).
- `Coin 10` at $(2250, -280)$: Stationed over `DisappearingPlatform7` before the exit.
- `ExitGate` at $(2375, -310)$: Anchored firmly on `ExitPlatform` ($X = 2365$, width $90\text{px}$).

---

## 6. Automated Test Suite Results

Headless execution via Godot 4.7.2 console binary:
```powershell
& "C:\Users\hp\godot\Godot_v4.7.2-stable_win64_console.exe" --headless "res://scenes/tests/test_runner.tscn"
```

### Verification Summary
- **Total Assertions Executed:** 3,550
- **Passed:** 3,550
- **Failed:** 0
- **Regression:** Levels 1–18 remain 100% untouched and passing.
- **Level 20:** Remains locked and unplayable (`can_play_level(20) == false`).
- **Control Sizes & Margins:** Formally asserted in test runner: Left $104 \times 104$ (`touch_margin = 8.0`), Right $104 \times 104$ (`touch_margin = 8.0`), Jump $124 \times 124$ (`touch_margin = 16.0`), $16\text{px}$ separation between directional buttons.
