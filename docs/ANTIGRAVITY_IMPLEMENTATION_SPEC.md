# COIN HELL --- Antigravity Implementation Specification

## Retro Rage Arcade \| First Playable Milestone

**Treat this document as the source of truth. Build working
functionality, not just mock-up screens.** Inspect the current workspace
first and preserve any useful existing work.

## 1. Product goal

Create an original 2D retro pixel-art-inspired Android game collection
called **RETRO RAGE ARCADE**. Only **COIN HELL** is playable initially.
The other three game cards are visible but marked **COMING SOON**.

For this milestone, create: - A polished main menu with four game
cards. - Coin Hell level selection showing all 20 planned levels. - Only
Level 1 unlocked on a fresh save. - A genuinely playable Coin Hell
Level 1. - Coin collection, counter, exit gate, death/retry, pause,
completion, sequential unlocking, and local save data. - GitHub-ready
source and a GitHub Actions workflow that attempts to build and upload a
debug Android APK.

**Do not build all 20 gameplay levels yet.** Level 1 is the only
implemented level. Levels 2--20 are visible and correctly locked
initially. If a later level becomes unlocked but its gameplay has not
been implemented, show a clear "unlocked but still being built"
message---never a blank scene.

## 1A. Mandatory visual/layout corrections from the recorded prototype

The current recorded prototype demonstrates that navigation and some gameplay are present, but its layout needs correction before expanding content. Treat these as required fixes, not optional polish:

1. **The APK currently appears in portrait orientation.** This is incorrect. Force the entire app to landscape at the project/export level and verify it on the phone. Do not rely on the user manually rotating the phone.
2. **The main-menu cards are excessively tall and mostly empty in portrait.** In landscape, use a balanced 2×2 grid of four compact, visually rich cards. Each card should use its available area intentionally: original icon/illustration, title, one-line description, and status/action. Coin Hell should be clearly highlighted as the only playable card.
3. **The level-select grid currently occupies only the top portion of the portrait screen, leaving a huge unused area.** In landscape, use the available screen efficiently. Show all 20 level tiles at once when practical, arranged as a clear 5-column × 4-row grid (20 tiles) or another layout with similarly efficient use of space. Keep the header compact and the tiles large enough to tap. Avoid a giant empty area below the grid.
4. **The gameplay world currently occupies only a narrow/top strip of the portrait screen.** In landscape, make the playfield use the majority of the viewport. The player, platforms, coins, hazards, and exit should be easy to see. Put the HUD in a compact top strip and touch controls in the bottom corners without covering important gameplay objects.
5. **Use readable text and clear hierarchy.** The game title, screen title, level number, coin counter, lock state, and primary action must be legible at normal phone viewing distance. Avoid tiny labels and low-contrast secondary text.
6. **Use screen space intentionally.** Menus should not look like desktop layouts squeezed into portrait. Gameplay should not place all the action in the top third with a large empty lower half. Design and test for landscape first.
7. **Dialogs must remain properly centred and sized in landscape.** A Coming Soon message should dim the background lightly, use a compact modal, and have a clear dismiss button. It must not obscure the entire screen unnecessarily.
8. **Verify actual phone orientation and scaling.** Take screenshots or record a test on the target Android phone after the orientation change. Inspect the main menu, level selection, gameplay, pause overlay, death overlay, and completion overlay.

These corrections take priority over adding extra ragebait effects or new levels.

## 2. Technology and constraints

-   Engine: **Godot 4.x** stable release.
-   Language: **GDScript**.
-   AI development: Antigravity.
-   Source control: Git/GitHub.
-   CI: GitHub Actions.
-   Target: Android APK; desktop/editor play-testing must also work.
-   Game genre: 2D side-scrolling platformer.
-   Orientation: **landscape** for all screens and gameplay, suitable
    for side-scrolling. Use responsive anchors/containers and preserve
    pixel-art proportions across mobile aspect ratios.
-   Save progress locally using Godot `user://` storage.
-   No account, backend, ads, analytics, payment, or network
    requirements in this milestone.
-   Use original names, art, characters, sprites, sound, UI, and level
    layouts. Do not copy Mario, Contra, Nintendo/Konami IP, logos,
    music, sprites, or recognizable level designs.
-   Use original art or clean procedural placeholders; missing final art
    must not block gameplay.
-   If a Godot project already exists, inspect and extend it instead of
    blindly replacing files. Do not delete working code without
    understanding it.
-   Do not commit secrets or Android signing credentials.

## 3. Identity and art direction

**App title:** RETRO RAGE ARCADE\
**First game:** COIN HELL\
**Tagline:** "Collect every coin. Trust nothing."

Visual direction: polished modern pixel-art-inspired arcade style, deep
navy/purple backgrounds, gold coins, coral/red danger cues, teal/cyan
highlights, bold readable headings, clear silhouettes, subtle
inexpensive particles/glow. Use a consistent style; avoid generic plain
admin-panel UI.

The main menu and level grid should feel like a finished indie game, not
a debug screen. Buttons need visible pressed/selected feedback and
readable labels. Avoid clipped text, overlapping controls, tiny touch
targets, and UI stretched out of proportion.

Sound hooks should be available for UI click, coin collection,
jump/land, death, exit unlock, and level completion. Use original audio
or silent fallbacks; do not delay a working build for audio assets. A
sound toggle is optional if easy to implement.

## 4. Inputs and responsive behaviour

Support keyboard controls in desktop/editor: - Left/A: move left. -
Right/D: move right. - Space/Up/W: jump. - Escape: pause or back
according to current screen; never unexpectedly terminate gameplay.

Android gameplay must have large on-screen **LEFT**, **RIGHT**, and
**JUMP** touch controls with pressed states. They must not overlap
essential HUD content or intercept menu clicks when gameplay is not
active.

Use responsive containers/anchors. Make the level grid scroll if
required. Test different window sizes and at least one real Android
phone when possible.

## 5. Navigation flow

Implement this exact main flow:

**Main Menu → Coin Hell Level Select → Level 1 Gameplay → Level Complete
→ Level Select**

Also implement: - Level Select → Main Menu using Back. - Gameplay →
Pause → Resume. - Gameplay → Pause → Restart Level. - Gameplay → Pause →
Level Select. - Death → Retry or Level Select. - Completion → Replay,
Level Select, and Next Level.

The Next Level action must not open a blank scene. If Level 2 is not
implemented, show a message that Level 2 is unlocked but still being
built, then offer return to level selection.

## 6. Main Menu screen

Show: 1. **RETRO RAGE ARCADE** title/logo. 2. Subtitle: **"Four games.
One very bad idea."** 3. Four large game cards, preferably a responsive
2×2 layout: - **COIN HELL** --- "Collect every coin. Trust nothing." ---
**PLAY NOW**. - **BULLET BETRAYAL** --- "Your ammo has trust issues."
--- **COMING SOON**. - **NINJA NIGHTMARE** --- "Every jump is a
questionable decision." --- **COMING SOON**. - **CASTLE OF LIES** ---
"That door is probably a mistake." --- **COMING SOON**. 4. An original
icon/illustration, distinct accent, title, description, and status for
each card. 5. Optional settings button and small prototype version
label.

Behaviour: - Tapping Coin Hell opens its level-selection screen. -
Tapping any Coming Soon card shows: **"This game is still in
development. Coin Hell is ready to cause trouble first."** - Coming Soon
cards must look intentionally locked, not broken. - All buttons must
respond and show feedback.

## 7. Coin Hell level-selection screen

Header: - Back button to main menu. - **COIN HELL** - Subtitle: **"20
levels. Zero trust."** - Progress text: **LEVELS CLEARED: 0 / 20** on a
fresh save. - Optional progress bar.

Show numbered tiles **1--20** in a readable responsive grid, ideally
four columns if it fits, otherwise adapt/scroll. Each tile must have a
number and unmistakable state: available, locked, or completed. Do not
rely on colour alone; use a lock/check/icon and text or visual shape.

State rules: - Fresh save: Level 1 available; Levels 2--20 locked; 0/20
cleared. - Completing Level N marks it completed and unlocks Level
N+1. - Levels already completed remain replayable. - Tapping a locked
level does not unlock it; show a playful message: **"Locked! Beat the
previous level first. The developer has enough problems already."** -
Level 1 opens gameplay. - If an unlocked level lacks a gameplay scene,
show: **"Level N is unlocked, but it's still being built. Replay Level 1
for now."** - Never route into a blank or missing scene. - Store highest
unlocked level and completed levels in local save data. - The 20 tiles
should make it clear that the game will grow, but only Level 1 is
implemented in this milestone.

Suggested level names: 1. The Warm-Up 2. Trust Issues 3. Coinception 4.
The Moving Floor 5. False Hope 6. Coin Thief 7. The Vanishing Path 8.
Greed Trap 9. The Fake Exit 10. Just One More 11. The Long Way 12.
Double Trouble 13. The Coin Switch 14. Nothing Is Safe 15. The Betrayal
16. Chaos Theory 17. No Turning Back 18. The Developer Laughs 19.
Dragon's Doorstep 20. Dragon's Den

Keep level definitions data-driven: ID, name, scene path, implemented
flag, objective/coin count, and optional mechanic IDs. Only Level 1 is
marked implemented initially.

## 8. Coin Hell Level 1: actual playable gameplay

Level title: **LEVEL 1 --- THE WARM-UP (TRUST US)**\
Objective: **COLLECT EVERY COIN TO OPEN THE EXIT**\
Target first-play duration: about 30--90 seconds.

Create a real side-scrolling level with: - Start area and player spawn
with safe ground. - A short route with flat ground and several platforms
at different heights. - One small, clearly visible and avoidable pit or
hazard. - Coins placed along a fair path that teaches movement and
jumping. - Visible exit gate near the end. - Camera follows player
horizontally. - World boundaries prevent walking off-screen except at
intended pits/hazards. - All required coins are reachable. - Use
original art or clear placeholder shapes if necessary.

### Player controls and physics

Implement responsive left/right movement with acceleration/deceleration,
gravity, jumping, floor/platform collision, and a stable camera. Add
modest coyote time and jump buffering if practical. No unintended double
jumps, clipping through floors, walking through walls, or getting stuck
in geometry. Tune for touch controls and test keyboard controls too.

If the player falls into a pit or touches a designated hazard: -
Freeze/disable gameplay input. - Show a short death overlay or respawn
flow. - Offer **RETRY** and **LEVEL SELECT**. - Retry must fully reset
player position, coin states/counter, hazards, and exit state. - The
player must never be left soft-locked.

### Coins

Use a configurable coin count; start with **10 coins**. HUD shows a
dynamic counter such as `COINS: 0 / 10`. Each coin can be collected only
once per run. On collection, play a brief feedback animation or effect,
remove/disable that coin, and update the HUD immediately. The counter
must never exceed the configured total. On death/retry, all coins return
and the counter resets to zero.

### Exit gate

The gate starts visibly closed/locked with a lock symbol and label
**COINS REQUIRED**. - If the player reaches it with coins remaining, do
not complete the level. Show **"You still need X coin(s)!"** - After the
final required coin is collected, visibly open/unlock the gate and show
**EXIT OPEN**. - Reaching the exit trigger after unlocking completes the
level exactly once. - Avoid duplicate completion events, duplicate
rewards, or multiple completion overlays.

### One gentle surprise

Optionally, the final coin may bounce or move a short distance when
approached. It must stay inside the playable area and remain
collectable. If this risks stability, omit it for now and leave a clean
hook for future ragebait mechanics. Level 1 should be fair and teach the
rules, not be brutally difficult.

### HUD and pause

Gameplay HUD: - `LEVEL 1 — THE WARM-UP` - Dynamic coin counter. -
`COLLECT EVERY COIN TO OPEN THE EXIT` - Pause button.

Pause overlay: - **RESUME** - **RESTART LEVEL** - **LEVEL SELECT** -
Optional SFX toggle.

The game world must actually pause behind the overlay while overlay
buttons remain responsive. Underlying gameplay must not receive taps
through overlays.

### Completion overlay

When all coins are collected and the player reaches the open exit: -
Stop movement and further gameplay input. - Show **LEVEL COMPLETE!** -
Show `COINS COLLECTED: 10 / 10` using the configured total. - Save
completion and unlock Level 2 immediately. - Buttons: **NEXT LEVEL**,
**LEVEL SELECT**, **REPLAY**. - NEXT LEVEL shows the
unimplemented-Level-2 message rather than opening a blank scene. - Save
progress exactly once and persist it even if the app closes immediately.

## 9. Local save system

Use a versioned save file under Godot `user://`, never in the source
folder. Store: - Save schema/version. - Highest unlocked Coin Hell
level. - Completed level IDs. - Optional music/SFX settings.

Defaults for missing or unreadable save: - Highest unlocked level = 1. -
Completed levels = empty. - Levels cleared = 0.

Handle corrupt/old save data gracefully without crashing; use safe
defaults when necessary. Save immediately after level completion/unlock
and when settings change. Completing Level 1 repeatedly must not
duplicate entries or corrupt progress. Keep save logic separate from UI
scenes.

## 10. Suggested project layout

Adapt to existing project conventions if they are sound, but keep
responsibilities clear:

``` text
res://
  project.godot
  README.md
  docs/
    ANTIGRAVITY_IMPLEMENTATION_SPEC.md
    TEST_PLAN.md
  scenes/
    ui/
      main_menu.tscn
      coin_hell_level_select.tscn
    coin_hell/
      coin_hell_level_1.tscn
      player.tscn
      coin.tscn
      exit_gate.tscn
    shared/
      pause_overlay.tscn
      death_overlay.tscn
      level_complete_overlay.tscn
  scripts/
    autoload/
      game_manager.gd
      save_manager.gd
      audio_manager.gd  # optional
    ui/
      main_menu.gd
      coin_hell_level_select.gd
    coin_hell/
      player.gd
      coin.gd
      exit_gate.gd
      level_1.gd
  assets/
    fonts/
    sprites/
    audio/
  .github/
    workflows/
      android-apk.yml
```

Do not create unused empty files just to match this tree. Prefer
understandable code over over-engineering.

Suggested responsibilities: - `GameManager`: current game/level,
navigation and level completion events. - `SaveManager`: read/write
local progress. - `AudioManager`: optional audio settings/playback
hooks. Use signals or clear function calls; avoid circular dependencies
and tangled global state.

## 11. GitHub and automated APK workflow

Create or update: - Godot-appropriate `.gitignore`. - `README.md` with
Godot version, how to open/run, and Android export setup. -
`docs/ANTIGRAVITY_IMPLEMENTATION_SPEC.md` containing this
specification. - `docs/TEST_PLAN.md`. -
`.github/workflows/android-apk.yml`.

Workflow requirements: - Trigger on pushes and pull requests to the
main/primary branch, plus manual `workflow_dispatch`. - Set up a
compatible Godot 4 headless environment and Android export
dependencies/templates. - Run a headless import/parse validation where
supported. - Export a debug APK to a predictable path such as
`build/coin-hell-debug.apk`. - Upload the APK as a GitHub Actions
artifact. - Fail clearly if validation/export fails. - Use stable/pinned
action versions where practical. - Never store signing passwords or
credentials in the repository. - If SDK/template setup or repository
permissions prevent a fully working workflow, create the best valid
workflow possible and document the exact manual steps. Do not claim an
APK was built unless an actual build succeeded.

The source project must still run in Godot editor even if Android export
is not yet configured locally. A debug APK is enough for this milestone;
Play Store signing/AAB setup is later work.

## 12. Error handling and quality bar

The task is not complete merely because scenes exist. Ensure: - Project
opens/imports without parse errors. - No missing scripts or scene
references. - Main menu and all implemented navigation work. - All
buttons have real behaviour. - Locked and not-yet-implemented levels
cannot crash the app. - Coin count updates correctly and never
overflows. - Retry resets the complete level state. - Pause actually
pauses gameplay. - Exit remains locked until all required coins are
collected. - Level completion happens only once. - Level 2 unlocks only
after Level 1 completion. - Progress survives app restart. - Touch
controls work and the player stays in the level. - No underlying
button/gameplay receives input through overlays. - Report anything that
could not be completed honestly.

## 13. Required test plan

Create `docs/TEST_PLAN.md` and test these cases.

**Main menu** - App starts at main menu. - Coin Hell opens level
select. - Each Coming Soon card shows the intended message. - Back
navigation works.

**Level selection** - Fresh save shows Level 1 available and Levels
2--20 locked. - Locked taps show feedback without unlocking. - Level 1
opens gameplay. - Grid is readable and scrollable on target
resolution. - Completion marks Level 1 completed and unlocks Level 2. -
Unimplemented Level 2 displays a placeholder, not a blank scene.

**Gameplay** - Movement, jumping, collision, camera and touch controls
work. - Every coin is reachable and collectible exactly once. - Counter
updates correctly. - Exit remains locked with coins remaining and
explains how many remain. - Final coin unlocks the exit. - Open exit
completes the level once. - Falling/touching a hazard produces
retry/respawn. - Retry restores all coins and locks the exit again. -
Pause, resume, restart and level-select actions work. - Completion saves
progress and unlocks Level 2.

**Persistence/build** - Close and relaunch after completion; progress
remains. - Missing/corrupt save does not crash. - Godot project opens
and runs. - Headless validation succeeds if supported. - GitHub Actions
exports and uploads an APK if the required environment is configured. -
Install the APK on an Android phone and verify screen layout and touch
controls.

## 14. Antigravity execution order

1.  **Inspect:** Report current workspace/project/Git/CI state. Preserve
    useful code.
2.  **Navigation shell:** Implement main menu, four cards, level select,
    20 tiles, states, messages and navigation.
3.  **Playable Level 1:** Implement player physics, platforms, coins,
    counter, exit gate, hazards, death/retry, pause and completion.
4.  **Progress/save:** Implement sequential unlocking and persistence.
5.  **Polish:** Original visual treatment, UI feedback, optional sounds,
    responsive layout, optional gentle final-coin surprise.
6.  **Validate:** Run the project, fix errors, and follow the test plan.
    Do not infer that code works just because it looks correct.
7.  **CI:** Add GitHub Actions workflow, README, ignore rules and docs.
8.  **Report:** List files created/changed, how to run, tests actually
    run/results, whether APK export really succeeded, where the artifact
    is, and remaining manual steps.

Make sensible small decisions without asking the user about every
detail. If blocked, explain the blocker and still complete useful work.
Prioritize a reliable playable Level 1 over ambitious effects. Do not
begin implementing Bullet Betrayal, Ninja Nightmare or Castle of Lies
gameplay before Coin Hell is stable.

## 15. Definition of done

-   [ ] Main menu opens and looks polished.
-   [ ] All four game cards are visible.
-   [ ] Coin Hell is the only playable game card.
-   [ ] Other three cards show Coming Soon feedback.
-   [ ] Coin Hell shows levels 1--20.
-   [ ] Fresh save unlocks only Level 1.
-   [ ] Locked levels cannot be entered.
-   [ ] Level 1 opens a real playable side-scrolling level.
-   [ ] Movement, jump, collision, camera and touch controls work.
-   [ ] All required coins can be collected; HUD counter is accurate.
-   [ ] Exit stays locked until all coins are collected.
-   [ ] Open exit completes Level 1 once.
-   [ ] Death/retry resets player, coins and exit.
-   [ ] Pause/resume/restart/level-select work.
-   [ ] Completion marks Level 1 done and unlocks Level 2.
-   [ ] Progress persists after relaunch.
-   [ ] Unimplemented unlocked levels show a safe placeholder.
-   [ ] Project opens without errors.
-   [ ] README and test plan exist.
-   [ ] GitHub Actions workflow is present and accurately reports build
    status.
-   [ ] Final report distinguishes verified features from untested or
    blocked ones.

**Build this milestone first. Do not build all 20 levels or the other
three games yet. The immediate goal is that I can launch the app, click
Coin Hell, see Level 1 unlocked and the others locked, click Level 1,
and actually play it.**
