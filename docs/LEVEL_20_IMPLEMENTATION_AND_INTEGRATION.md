# RETRO RAGE ARCADE: LEVEL 20 IMPLEMENTATION & ARCHITECTURE
## World 4: Final Hell — Stage 5 (Boss Stage): THE FINAL BETRAYAL
### Final Boss Encounter: The Coin Dragon

**Document Version:** 1.0.0  
**Target Engine:** Godot 4.7.2-stable (Win64 / Android API 36)  
**Branch:** `migration/android-api36-godot47`  

---

## 1. Executive Summary & Level Identity

**Level 20 — THE FINAL BETRAYAL** serves as the ultimate climax of **RETRO RAGE ARCADE (World 4: Final Hell)** and the culmination of the entire Coin Hell campaign. 

Following the precision platforming gauntlets of Levels 16–19, Level 20 transforms the gameplay paradigm into a **high-stakes 60-second survival boss arena** against **THE COIN DRAGON**—a gigantic, golden infernal beast forged from demon gold and brimstone.

### Core Encounter Pillars
1. **60-Second Survival Requirement:** The player must survive in the arena against the Coin Dragon for a total active duration of 60.0 seconds.
2. **10 Collectible Coins:** Every 6 seconds ($T = 6, 12, 18, 24, 30, 36, 42, 48, 54, 60$), the Coin Dragon halts, rears back, roars hellfire, and releases a golden collectible coin across the arena platforms.
3. **Lethal Contact Slaying:** Touching the Coin Dragon's body or horns results in immediate player death.
4. **Dual-Condition Gate Unlocking:** The Infernal Exit Gate at the summit sanctuary remains strictly locked until **BOTH** 60 seconds have elapsed **AND** all 10 coins have been collected.
5. **Boss Defeat Sequence:** Stepping through the unlocked gate triggers the Coin Dragon's dissolution sequence, awarding 3 stars and completing World 4.

---

## 2. The Boss — The Coin Dragon Architecture

### A. Visuals & Authentic Pixel Art
The Coin Dragon is an oversized ($112 \times 80\text{px}$) retro arcade boss featuring:
- **Torso:** A massive golden coin medallion ($54\text{px}$ diameter) with milled serrations, luster arcs, and an embossed roaring rage-demon face.
- **Head & Cranium:** Swept-back obsidian horns with glowing crimson tips, burning reptilian eyes with slit pupils, and sharp ivory teeth.
- **Limbs & Talons:** Muscular scaled legs with sharp talons.
- **Tail:** Segmented tail with razor dorsal spines, culminating in a golden blade spade.
- **Wings:** Upper dorsal wings that flare during leaps and roars.

### B. Sprite Frames
- `coin_dragon_idle.png`: Stalking stance, breathing embers.
- `coin_dragon_walk.png`: Forward stride with moving legs and swaying tail.
- `coin_dragon_jump.png`: Flared wings, retracted legs, airborne silhouette.
- `coin_dragon_roar.png`: Gaping maw with internal flame burst, used during coin releases.

### C. Physical & Combat Mechanics
- **Physics Class:** `CharacterBody2D` with `move_and_slide()` interaction against platforms and arena boundaries (`collision_mask = 2`).
- **Speed:** $v_x = 160.0\text{ px/s}$ (formidable pace, intentionally tuned below the player's $240.0\text{ px/s}$ to allow evasion and juking).
- **Jump Physics:** $v_y = -440.0\text{ px/s}$, $g = 1150.0\text{ px/s}^2$.
- **Hazard Contact Area:** `Area2D` on hazard layer 4 with continuous distance checking, preventing tunneling.

---

## 3. Platform Arena Design & Jump Kinematics

The encounter takes place in a bounded $960 \times 540$ arena, ensuring the player has 100% full-screen situational awareness without camera disorientation or blind-spot jumps.

### Platform Layout (10 Platforms)
| Platform | Position (`X, Y`) | Dimensions (`W, H`) | Function / Tier |
| :--- | :---: | :---: | :--- |
| `LeftGround` | $(140, 460)$ | $180 \times 20\text{px}$ | Safe player spawn runway |
| `CenterBridge` | $(480, 440)$ | $220 \times 20\text{px}$ | Lower arena crossing bridge |
| `RightGround` | $(820, 460)$ | $180 \times 20\text{px}$ | Right flank landing & dragon start |
| `LeftStep` | $(190, 385)$ | $100 \times 18\text{px}$ | Intermediate stepping stone to left mid |
| `LeftMid` | $(130, 310)$ | $130 \times 18\text{px}$ | Elevated left perch |
| `MidLeftPerch` | $(320, 260)$ | $110 \times 18\text{px}$ | Stepping stone to Central Altar |
| `CentralAltar` | $(480, 195)$ | $130 \times 20\text{px}$ | Summit sanctuary with Infernal Exit Gate |
| `MidRightPerch`| $(640, 260)$ | $110 \times 18\text{px}$ | Stepping stone down to right flank |
| `RightMid` | $(830, 310)$ | $130 \times 18\text{px}$ | Elevated right perch |
| `RightStep` | $(770, 385)$ | $100 \times 18\text{px}$ | Intermediate stepping stone to right ground |

### Kinematic Reachability Verification
All player jumps verified with engine parameters ($v_x = 240, v_0 = -470, g = 1150, H_{max} = 96.04\text{px}$):
- `LeftGround` $\to$ `LeftStep`: $\Delta y = +75\text{px} \le 96.04\text{px}$ (Vertical hop)
- `LeftStep` $\to$ `LeftMid`: $\Delta y = +75\text{px} \le 96.04\text{px}$ (Vertical hop)
- `LeftMid` $\to$ `MidLeftPerch`: $\text{Gap} = 70\text{px}, \Delta y = +50\text{px}$, Reach = $165.7\text{px}$ (Margin: $+95.7\text{px}$)
- `MidLeftPerch` $\to$ `CentralAltar`: $\text{Gap} = 40\text{px}, \Delta y = +65\text{px}$, Reach = $153.9\text{px}$ (Margin: $+113.9\text{px}$)
- `CentralAltar` $\to$ `MidRightPerch`: $\text{Gap} = 40\text{px}, \Delta y = -65\text{px}$, Reach = $225.1\text{px}$ (Margin: $+185.1\text{px}$)
- `MidRightPerch` $\to$ `RightMid`: $\text{Gap} = 70\text{px}, \Delta y = -50\text{px}$, Reach = $216.5\text{px}$ (Margin: $+146.5\text{px}$)
- `LeftGround` $\to$ `CenterBridge`: $\text{Gap} = 140\text{px}, \Delta y = +20\text{px}$, Reach = $185.4\text{px}$ (Margin: $+45.4\text{px}$)
- `CenterBridge` $\to$ `RightGround`: $\text{Gap} = 140\text{px}, \Delta y = -20\text{px}$, Reach = $205.9\text{px}$ (Margin: $+65.9\text{px}$)

---

## 4. Coin Release Schedule & Distribution

The 10 coins are released at exact 6-second intervals and land on reachable solid platforms:
- **Coin 1** ($T = 6\text{s}$): `LeftStep` at $(190, 360)$
- **Coin 2** ($T = 12\text{s}$): `CenterBridge Left` at $(420, 415)$
- **Coin 3** ($T = 18\text{s}$): `MidLeftPerch` at $(320, 235)$
- **Coin 4** ($T = 24\text{s}$): `RightStep` at $(770, 360)$
- **Coin 5** ($T = 30\text{s}$): `CenterBridge Right` at $(540, 415)$
- **Coin 6** ($T = 36\text{s}$): `LeftMid` at $(130, 285)$
- **Coin 7** ($T = 42\text{s}$): `RightMid` at $(830, 285)$
- **Coin 8** ($T = 48\text{s}$): `MidRightPerch` at $(640, 235)$
- **Coin 9** ($T = 54\text{s}$): `CenterBridge Middle` at $(480, 415)$
- **Coin 10** ($T = 60\text{s}$): `CentralAltar Sanctuary` at $(480, 170)$

Missed coins persist in the arena until retrieved; they are never destroyed or despawned.

---

## 5. Controls Parity with Levels 16–19

The on-screen virtual touch controls match the standard established in Levels 16–19:
- `LeftBtn`: $104 \times 104\text{px}$, offsets `(24, -128, 128, -24)`, `touch_margin = 8.0`
- `RightBtn`: $104 \times 104\text{px}$, offsets `(144, -128, 248, -24)`, `touch_margin = 8.0`
- Spacing: $16\text{px}$ gap between Left and Right buttons (`144 - 128 = 16`)
- `JumpBtn`: $124 \times 124\text{px}$, offsets `(-148, -148, -24, -24)`, `touch_margin = 16.0`
