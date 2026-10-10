# RETRO RAGE ARCADE: COIN HELL — TEST PLAN

This document specifies the verification plan, automated test coverage, and manual QA procedures for the **Retro Rage Arcade: Coin Hell (Milestone 1)** release.

---

## 1. Automated Test Suite

An automated test suite is implemented in [`scripts/tests/test_runner.gd`](file:///c:/AntiGravity/rage_bait/scripts/tests/test_runner.gd) and can be executed headlessly via:
```bash
godot --headless "res://scenes/tests/test_runner.tscn"
```

### Automated Coverage Matrix (75 Assertions)

| Category | Test Case | Expected Result | Status |
| :--- | :--- | :--- | :---: |
| **Save / Persistence** | Fresh save defaults | Highest unlocked = 1, completed = 0 | **PASS** |
| **Save / Persistence** | Sequential unlock | Completing Level 1 unlocks Level 2 | **PASS** |
| **Save / Persistence** | Disk persistence | Progress survives save file reload | **PASS** |
| **Save / Persistence** | Corrupt save resilience | Graceful fallback to safe defaults without crash | **PASS** |
| **Game Data** | 20 planned levels | All 20 levels cataloged with official names | **PASS** |
| **Game Data** | Playable state | Only Level 1 is playable initially | **PASS** |
| **Game Data** | Coin counter clamp | Counter never exceeds configured total (10) | **PASS** |
| **Main Menu** | Card availability | All 4 arcade cards present | **PASS** |
| **Main Menu** | Coming soon modals | Modal shows exact spec message when locked card clicked | **PASS** |
| **Level Select** | 20 level tiles | Responsive grid contains all 20 tiles | **PASS** |
| **Level Select** | Locked tile modal | Tapping locked tile shows spec message | **PASS** |
| **Level Select** | Unimplemented modal | Tapping unlocked Level 2 shows "still being built" message | **PASS** |
| **Gameplay** | Entity instantiation | Player, 10 coins, hazards, exit gate present | **PASS** |
| **Gameplay** | Exit gate locked state | Gate begins locked with "COINS REQUIRED" | **PASS** |
| **Gameplay** | Gate feedback | Approaching gate early shows remaining coins toast | **PASS** |
| **Gameplay** | Coin collection | Collecting 10th coin unlocks gate ("EXIT OPEN!") | **PASS** |
| **Gameplay** | Exit completion | Touching open gate triggers completion exactly once | **PASS** |
| **Gameplay** | Retry reset | Resets player position, resets coins (0/10), locks gate | **PASS** |
| **Gameplay** | Hazard & Death | Hazard triggers death overlay without soft lock | **PASS** |

---

## 2. Manual QA Matrix (Desktop & Android)

### A. Main Menu
1. **Launch App**: Verify window opens to Main Menu with deep navy arcade theme.
2. **Audio Toggle**: Click "SFX: ON/OFF" button. Verify text toggles and sound state persists.
3. **Coming Soon Cards**: Click "Bullet Betrayal", "Ninja Nightmare", and "Castle of Lies".
   - *Expected*: Popup appears: *"This game is still in development. Coin Hell is ready to cause trouble first."*
4. **Coin Hell Card**: Click "Coin Hell".
   - *Expected*: Smooth transition to Level Select screen.

### B. Level Select Screen
1. **Fresh Save Inspection**: Verify Level 1 is highlighted as `AVAILABLE`, Levels 2–20 are marked `LOCKED` with lock icons.
2. **Progress Display**: Verify header shows `LEVELS CLEARED: 0 / 20` and progress bar at 0%.
3. **Locked Tile Tap**: Tap Level 2 or Level 10.
   - *Expected*: Popup appears: *"Locked! Beat the previous level first. The developer has enough problems already."*
4. **Launch Level 1**: Tap Level 1 tile.
   - *Expected*: Seamless transition into Level 1 gameplay.

### C. Level 1 Gameplay & Platforming Physics
1. **Desktop Controls**:
   - `A` / `Left Arrow`: Walk left.
   - `D` / `Right Arrow`: Walk right.
   - `W` / `Up Arrow` / `Space`: Jump.
   - `Escape`: Pause.
2. **Android On-Screen Controls**:
   - Press left arrow on-screen button: player moves left.
   - Press right arrow on-screen button: player moves right.
   - Press jump on-screen button: player jumps.
   - Verify jump buffering and coyote time allow smooth platform jumps.
3. **Camera Follow**: Walk right across platforms. Verify smooth horizontal tracking with camera boundaries at level edges.
4. **Coin Collection**:
   - Collect coins 1 through 9. Verify HUD counter increments: `COINS: 1 / 10` ... `COINS: 9 / 10`.
   - Approach Coin 10 (surprise coin): Observe the gentle hop to a nearby safe spot. Collect it.
   - Verify HUD reads `COINS: 10 / 10`.
5. **Exit Gate Logic**:
   - Approach exit gate *before* collecting all coins: Verify gate remains closed with red lock and shows toast: *"You still need X coin(s)!"*
   - Collect 10th coin: Verify gate lights up cyan and displays *"EXIT OPEN!"*.
   - Walk into open gate: Verify level completion overlay appears.
6. **Hazards & Pit**:
   - Walk into the spikes or drop into the pit gap.
   - Verify death sound plays, player input is locked, and Death Overlay appears with "YOU DIED!" and "Trust is a luxury you cannot afford."
   - Click "↺ RETRY LEVEL": Verify player respawns at spawn point, coin counter resets to `COINS: 0 / 10`, all coins reappear, and exit gate relocks.
7. **Pause Overlay**:
   - Tap `⏸ PAUSE` during gameplay.
   - Verify game world pauses.
   - Tap "▶ RESUME" -> gameplay resumes.
   - Tap "↺ RESTART LEVEL" -> level resets.
   - Tap "☰ LEVEL SELECT" -> returns to level selection.

### D. Completion & Progression
1. **Level Complete Overlay**:
   - After beating Level 1, verify overlay displays:
     - `LEVEL COMPLETE!`
     - `COINS COLLECTED: 10 / 10`
   - Tap "▶ NEXT LEVEL":
     - *Expected*: Shows modal: *"Level 2 is unlocked, but it's still being built. Replay Level 1 for now."*
   - Tap "☰ LEVEL SELECT":
     - *Expected*: Level 1 is now marked `COMPLETED` with check icon. Level 2 is now marked `AVAILABLE`. Progress reads `LEVELS CLEARED: 1 / 20`.
2. **Persistence After Relaunch**:
   - Close app completely and reopen.
   - Navigate to Level Select: Level 1 remains completed, Level 2 remains unlocked.

### E. Landscape Orientation & Visual Polish Verification (Section 1A)
1. **Forced Landscape Orientation**:
   - Verify `window/handheld/orientation = 0` in `project.godot`.
   - Verify `screen/orientation = 0` in `export_presets.cfg`.
   - Verify runtime orientation enforcement in `game_manager.gd`.
   - On Android, verify app launches locked in landscape regardless of physical phone rotation.
2. **Main Menu 2x2 Grid**:
   - Verify 4 compact, visually balanced arcade cards in a 2x2 responsive grid.
   - Coin Hell is prominently highlighted with an arcade gold glowing border, shadow, and vivid "▶ PLAY NOW" badge.
   - Other three cards feature muted cyber slate borders and "🔒 COMING SOON" indicators.
3. **Level Select 5x4 Grid (20 Tiles)**:
   - Verify all 20 tiles are displayed simultaneously in a 5-column x 4-row layout without wasted space.
   - Completed (emerald border/star), Available (gold border/glow), Locked (slate/lock icon).
4. **Landscape Gameplay Viewport**:
   - Playfield utilizes the full 960x540 landscape viewport.
   - HUD is kept in a compact top strip (< 55px).
   - Touch buttons are positioned in bottom corners (Left/Right bottom-left, Jump bottom-right) with visible pressed states and comfortable thumb target sizes.
5. **Landscape Modals & Dialogs**:
   - All modals (Coming Soon, Locked Level, Level In Progress) are neatly centered in landscape with 65% dimming and explicit dismiss buttons.

