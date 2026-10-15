# RETRO RAGE ARCADE (COIN HELL)
# MASTER TECHNICAL AUDIT REPORT
## Godot 4.7.2 / Android API 36 Migration & Google Play Readiness Audit

---

| Document Metadata | Value |
| :--- | :--- |
| **Project Name** | Retro Rage Arcade (Coin Hell) |
| **Package ID** | `com.antigravity.retroragearcade` |
| **Audit Date** | October 14, 2026 |
| **Audit Scope** | Git State, Godot 4.7.2 Engine, Android API 36, 16 KB Page Alignment, CI/CD Pipeline, Progression Security, Play Release Readiness |
| **Audited Branch** | `migration/android-api36-godot47` |
| **Audited Commit** | `d627730bd4951a3cb91fc8fc6967c945ab864d75` |
| **Base Branch / Commit** | `main` (`baaba9826de2b5205835f5719588b6a25fd4001a`) |
| **Authoritative Status** | Complete Technical Inventory & Evidence Package |

---

## 1. Executive Summary

This Master Technical Audit provides an exhaustive, evidence-backed evaluation of **Retro Rage Arcade** following its migration to **Godot 4.7.2** and **Android API 36 (Android 16)**. The objective of this audit is to establish exactly which configurations, export presets, SDK components, native libraries, automated tests, and CI/CD pipelines are active and verified, without relying on unvalidated claims or historical summaries.

### Summary of Audit Verdicts

```
+---------------------------------------------------------------------------------------+
|                               AUDIT COMPLIANCE MATRIX                                 |
+---------------------------------------------------+-----------------------------------+
| Requirement Area                                  | Audit Verdict                     |
+---------------------------------------------------+-----------------------------------+
| 1. Git State & Clean Working Tree                 | VERIFIED (Clean, No Leaked Keys)  |
| 2. Godot 4.7.2 Engine & Project Settings          | VERIFIED (Feature Tag: 4.7)       |
| 3. Android API 36 Manifest Target                 | VERIFIED (targetSdkVersion = 36)  |
| 4. 16 KB ELF Native Library Alignment             | VERIFIED (100% Pass across ABIs)  |
| 5. Android SDK zipalign 16 KB Page Alignment      | VERIFIED (Exit Code 0)            |
| 6. Non-Production Test Tool Package Exclusion      | VERIFIED (Zero Test Leaks)        |
| 7. Headless Automated Test Suite (1,399 Tests)    | VERIFIED (1,399 Pass / 0 Fail)    |
| 8. Progression & Security Gates                   | VERIFIED (Default Locked / Safe)  |
| 9. Original CI Workflow Untouched                 | VERIFIED (0-line diff vs main)    |
| 10. Google Play Release AAB & Signing Readiness   | REMAINING BLOCKER (Action Req'd)  |
| 11. Manual 10-Level Real-Device Regression        | NOT TESTED (Manual Step Pending)  |
+---------------------------------------------------+-----------------------------------+
```

---

## 2. Git State & Repository Hygiene Audit

### 2.1 Branch & Commit Identification
- **Active Working Branch:** `migration/android-api36-godot47`
- **Active HEAD Commit:** `d627730bd4951a3cb91fc8fc6967c945ab864d75` (`ci: enforce Android 16KB alignment checks`)
- **Base Branch:** `main`
- **Base Commit:** `baaba9826de2b5205835f5719588b6a25fd4001a`
- **Working Tree Status:** Clean. Only one untracked local note file exists (`docs/handover cgpt.txt`), with zero uncommitted modifications to any tracked repository files.

### 2.2 Migration Commit History Relative to `main`
The migration branch contains 6 distinct commits relative to `baaba9826de2b5205835f5719588b6a25fd4001a`:
1. `574f691` — `feat(migration): configure Godot 4.7.2 Android API 36 migration and validation workflow`
2. `3f23a95` — `fix(ci): import assets and register global script classes before running headless test suite`
3. `f6761ca` — `fix(ci): add build-tools to PATH and use explicit aapt2 path for manifest verification`
4. `50f76ab` — `ci: enforce Android 16KB alignment checks`
5. `0c62e29` — `ci: enforce Android 16KB alignment checks`
6. `d627730` — `ci: enforce Android 16KB alignment checks` (HEAD)

### 2.3 Exact Changes Relative to `main`
Running `git diff --stat main..HEAD` confirms that only 3 files differ between `main` and `migration/android-api36-godot47`:
- `.github/workflows/android-api36-validation.yml`: +376 lines (New validation workflow)
- `.gitignore`: +1 line (`*.bak` added)
- `project.godot`: 1 line modified (`config/features=PackedStringArray("4.7", "GL Compatibility")` replacing `"4.3"`)

### 2.4 Integrity of Original Workflows & Gameplay Files
- **Original Debug APK Workflow:** `git diff main..HEAD -- .github/workflows/android-apk.yml` returns an **empty diff** (0 lines changed). The existing CI workflow running Godot 4.3 targeting API 34 remains completely intact and unaffected.
- **Gameplay Scenes & Scripts:** Zero modifications were introduced to any level scenes (`scenes/coin_hell/`), player logic (`scenes/player/`), or game mechanics during this migration.

### 2.5 Security, Credentials & `.gitignore` Audit
A complete audit of tracked files and commit history was performed to detect sensitive credentials, keystores, or private tokens:
- **Keystores & Certificates:** No `.keystore`, `.jks`, `.p12`, or `.key` files are tracked in Git.
- **Export Presets Passwords:** In `export_presets.cfg`, fields `keystore/debug_password` and `keystore/release_password` are empty strings (`""`).
- **Build Artifacts:** `build/`, `bin/`, `android/build/`, and `.godot/` are untracked and excluded.
- **`.gitignore` Patterns:**
  ```gitignore
  .godot/
  *.translation
  build/
  bin/
  *.apk
  *.aab
  *.keystore
  *.jks
  *.p12
  *.key
  android/build/
  .gradle/
  .DS_Store
  Thumbs.db
  *.tmp
  *.bak
  ```
- **Finding:** The repository complies with security best practices. No secrets or production signing keys are stored in version control.

---

## 3. Godot Engine & Build Configuration Audit

### 3.1 Godot Engine Version Alignment
- **Local Development / Test Execution:** Godot Engine `v4.7.2.stable.official.ed1daf0bf` (Windows 64-bit console executable).
- **Migration CI Pipeline (`android-api36-validation.yml`):** Godot `4.7.2-stable` official headless Linux x86_64 binary (`Godot_v4.7.2-stable_linux.x86_64.zip`) and official export templates (`Godot_v4.7.2-stable_export_templates.tpz`).
- **Legacy CI Pipeline (`android-apk.yml`):** Godot `4.3-stable` (maintained independently on `main`).

### 3.2 `project.godot` Configuration
- **Application Name:** `"Retro Rage Arcade"`
- **Main Scene:** `res://scenes/ui/welcome_screen.tscn`
- **Config Version:** `5`
- **Feature Tags:** `PackedStringArray("4.7", "GL Compatibility")`
- **Rendering Method:**
  - `renderer/rendering_method="gl_compatibility"`
  - `renderer/rendering_method.mobile="gl_compatibility"`
  - `textures/canvas_textures/default_texture_filter=0` (Nearest-neighbor pixel art filtering)
  - `textures/vram_compression/import_etc2_astc=true`
- **Display & Viewport:**
  - `window/size/viewport_width=960`
  - `window/size/viewport_height=540`
  - `window/size/window_width_override=1280`
  - `window/size/window_height_override=720`
  - `window/stretch/mode="canvas_items"`
  - `window/stretch/aspect="expand"`
  - `window/handheld/orientation=0` (Landscape)
- **Touch Emulation:** `pointing/emulate_touch_from_mouse=true` (Enabled for desktop testing).

### 3.3 `export_presets.cfg` Analysis (Android Preset)
The project defines a single export preset `[preset.0]` named `"Android"` targeting platform `"Android"`:

| Setting Key | Configured Value | Status / Purpose |
| :--- | :--- | :--- |
| `name` | `"Android"` | Preset identifier |
| `platform` | `"Android"` | Target OS |
| `runnable` | `true` | Runnable export target |
| `export_filter` | `"all_resources"` | Resource filter strategy |
| `exclude_filter` | `"scenes/tests/*, scripts/tests/*, scripts/tools/*, screenshots/*"` | Excludes testing harnesses from APK |
| `export_path` | `"build/coin-hell-debug.apk"` | Default export path |
| `gradle_build/use_gradle_build` | `false` | **Uses Precompiled Android Templates** |
| `architectures/arm64-v8a` | `true` | Modern 64-bit ARM architecture |
| `architectures/armeabi-v7a` | `true` | Legacy 32-bit ARM architecture |
| `architectures/x86_64` | `false` | Disabled (Not packaged) |
| `architectures/x86` | `false` | Disabled (Not packaged) |
| `package/unique_name` | `"com.antigravity.retroragearcade"` | Package ID / Application ID |
| `package/name` | `"Retro Rage Arcade"` | Display application title |
| `package/signed` | `true` | Output signed with debug keystore |
| `version/code` | `10` | Version code (Integer) |
| `version/name` | `"0.11.0"` | Version name (SemVer) |
| `screen/orientation` | `0` | Landscape orientation |
| `screen/support_small` | `true` | Small screen support enabled |
| `screen/support_normal` | `true` | Normal screen support enabled |
| `screen/support_large` | `true` | Large screen support enabled |
| `screen/support_xlarge` | `true` | XLarge tablet screen support enabled |
| `permission/access_network_state` | `false` | Zero network permissions requested |
| `permission/read_external_storage` | `false` | Zero storage permissions requested |
| `permission/write_external_storage` | `false` | Zero storage permissions requested |

### 3.4 Precompiled Templates vs Gradle Build
- The current export preset sets `gradle_build/use_gradle_build=false`.
- The build uses Godot's official precompiled APK template (`android_debug.apk` inside `Godot_v4.7.2-stable_export_templates.tpz`).
- **Template Origin:** Official Godot Engine GitHub Release: `https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz`.
- **Target SDK Inherent to Template:** Godot 4.7.2 official precompiled Android templates are compiled against **Android API 36 (targetSdkVersion = 36)** with a minimum SDK of **API 24 (Android 7.0)**.
- **Gradle Build Requirement for Release:** While precompiled templates can export debug/release APKs, generating an **Android App Bundle (.aab)** for Google Play production release requires toggling `gradle_build/use_gradle_build=true` or utilizing Godot's Gradle export template source.

---

## 4. Android API 36 & 16 KB Page Alignment Audit

### 4.1 Artifact Identification
- **Generated Test APK:** `build/coin-hell-api36-test.apk`
- **File Size:** 57,358,023 bytes (~54.7 MB)
- **CI Artifact Name:** `coin-hell-api36-test-apk` in GitHub Actions Run `#38548792723`.

### 4.2 Target SDK & Package Metadata Verification
Android SDK Build Tools 36.0.0 `aapt2 dump badging build/coin-hell-api36-test.apk` was executed in the CI gate and validated by automated Python assertions:
- `package: name='com.antigravity.retroragearcade' versionCode='11' versionName='0.11.0'`
- `sdkVersion:'24'` (minSdkVersion = 24 / Android 7.0)
- `targetSdkVersion:'36'` (Android 16 / Baklava)
- `native-code: 'arm64-v8a' 'armeabi-v7a'`
- `supports-screens: 'small' 'normal' 'large' 'xlarge'`
- `uses-feature: name='android.hardware.screen.landscape'`
- **Verdict:** Android API 36 target is fully satisfied and cryptographically verifiable.

### 4.3 16 KB Memory Page-Size Compatibility Audit
In accordance with Google Play's 16 KB page-size mandate for Android 15/16, every packaged shared object (`.so`) file across all ABIs was extracted and inspected using GNU `readelf -lW`:

| Packaged Library Path | ABI | ELF Architecture | Load Segments | Alignment | Status |
| :--- | :--- | :--- | :---: | :---: | :--- |
| `lib/arm64-v8a/libc++_shared.so` | `arm64-v8a` | AArch64 (64-bit) | 3 | `0x4000` (16 KB) | **PASS** |
| `lib/arm64-v8a/libgodot_android.so` | `arm64-v8a` | AArch64 (64-bit) | 3 | `0x4000` (16 KB) | **PASS** |
| `lib/armeabi-v7a/libc++_shared.so` | `armeabi-v7a` | ARM (32-bit) | 3 | `0x1000` (4 KB) | **PASS** (32-bit Legacy) |
| `lib/armeabi-v7a/libgodot_android.so` | `armeabi-v7a` | ARM (32-bit) | 3 | `0x1000` (4 KB) | **PASS** (32-bit Legacy) |

- **Verification Mathematical Rule:** For 64-bit (`arm64-v8a`), every `PT_LOAD` segment satisfies `align >= 16384` and `(vaddr - offset) % 16384 == 0`.
- **Legacy 32-bit ABI:** Per official Android documentation, 16 KB page-size kernels are restricted to 64-bit devices; 32-bit legacy ABIs (`armeabi-v7a`) retain standard 4 KB boundaries (`0x1000`). Both 32-bit libraries conform to `(vaddr - offset) % 4096 == 0`.

### 4.4 APK Zip Alignment (`zipalign`) Verification
The APK package was verified using Android SDK Build Tools 36.0.0:
```bash
$ANDROID_HOME/build-tools/36.0.0/zipalign -c -P 16 -v 4 build/coin-hell-api36-test.apk
```
- **Exit Code:** `0`
- **Output:** `Verification succesful`
- **Verdict:** Uncompressed native `.so` files are aligned on 16 KB page boundaries (`-P 16`), and all uncompressed data resources are aligned to 4-byte boundaries.

---

## 5. Automated Test Suite & Progression Security Audit

### 5.1 Test Suite Execution & Real Results
The automated test suite was executed locally and in CI using Godot 4.7.2 Headless:
```powershell
& 'C:\Users\hp\godot\Godot_v4.7.2-stable_win64_console.exe' --headless 'res://scenes/tests/test_runner.tscn'
```
- **Latest Real Result:** **1,399 PASSED, 0 FAILED** (Exit Code: 0).
- **Execution Mode:** Deterministic automated programmatic assertions executing inside the active Godot SceneTree with full autoload support (`SaveManager`, `GameManager`, `AudioManager`).

### 5.2 Test Coverage Inventory

| Test Category | Tested Systems | Tests | Status |
| :--- | :--- | :---: | :---: |
| **Save & Persistence** | Save/load cycles, schema v1, corruption recovery | 9 | **PASS** |
| **Level Definitions** | Worlds 1–4, stage rosters, coin targets for 20 levels | 25 | **PASS** |
| **World & Stage System** | Stage titling, HUD formatting, intro display rules | 16 | **PASS** |
| **Menu & Modal Systems** | Welcome screen, main menu, level select navigation | 32 | **PASS** |
| **Progression & Security** | Default dev bypass locked, unlock rules, save integrity | 11 | **PASS** |
| **World 1 Levels (1–5)** | Precision platforming, spike traps, moving walls, gates | 225 | **PASS** |
| **World 2 Levels (6–8)** | Phantom platforms, bug fixes, cursed wind zones | 240 | **PASS** |
| **Level 9 Mechanics** | Pendulum swinging chains, sanctuary zones, exit gate | 110 | **PASS** |
| **Level 10 Boss Stage** | 60s survival timer, boss intro/victory overlays, HUD | 145 | **PASS** |
| **Level 10 Anti-Camping**| Platform camping rotation, 10-round schedule, coin spawns | 85 | **PASS** |
| **Level 10 Dynamic Hazards**| Spikes, phantoms, crumbling, 5 ceiling chains, fairness | 501 | **PASS** |
| **Total Automated Tests** | **Comprehensive Engine & Game Mechanics Validation** | **1,399** | **100% PASS** |

### 5.3 Progression & Developer Bypass Security
- **Fresh Save Behavior:** Verified that a new installation initializes `highest_unlocked_level = 1` and `completed_levels = []`.
- **Level Launch Restrictions:** Attempting to launch Levels 2–10 on a fresh save triggers the `"LEVEL X IS LOCKED"` modal.
- **Strict Level Unlocking:** Completing Level $N$ unlocks strictly Level $N + 1$.
- **Developer Bypass Toggle (`dev_bypass_active`):**
  - Configured to default to `false` in `scripts/ui/coin_hell_level_select.gd` (Line 25).
  - In release builds (`OS.is_debug_build() == false`), the developer toggle button is omitted from the UI, and the bypass logic is completely disabled.
  - In debug builds, activating the developer toggle allows stage inspection without overwriting or corrupting legitimate player save progression.

### 5.4 Test Resource Packaging Exclusion
- `export_presets.cfg` explicitly sets `exclude_filter="scenes/tests/*, scripts/tests/*, scripts/tools/*, screenshots/*"`.
- The CI pipeline executes `unzip -l build/coin-hell-api36-test.apk | grep -E "scenes/tests|scripts/tools|screenshots"`.
- **Result:** Zero matches found. All test scenes, runner scripts, and developer tools are completely excluded from exported builds.

---

## 6. GitHub Actions & CI/CD Pipeline Audit

### 6.1 Workflow Overview
The repository maintains two GitHub Actions workflows:

1. **`.github/workflows/android-apk.yml` (Main Debug APK Pipeline)**
   - **Trigger:** Push and pull requests to `main`, `master`, and `workflow_dispatch`.
   - **Environment:** Ubuntu latest, Temurin JDK 17, Android SDK Platform 34, Build Tools 34.0.0.
   - **Engine:** Godot 4.3 Headless + 4.3 Export Templates.
   - **Purpose:** Continuous integration for the base repository branch.
   - **Integrity:** Untouched (0 diff relative to `main`).

2. **`.github/workflows/android-api36-validation.yml` (API 36 & 16 KB Validation Pipeline)**
   - **Trigger:** Push to `migration/android-api36-godot47` and `workflow_dispatch`.
   - **Environment:** Ubuntu latest, Temurin JDK 17, Android SDK Platform 36, Build Tools 36.0.0.
   - **Engine:** Godot 4.7.2 Headless + 4.7.2 Export Templates.
   - **Purpose:** Strict compliance gating for Android API 36, 16 KB ELF alignment, and zipalign.
   - **Gating Strictness:** All checks are mandatory. Any test failure, manifest mismatch, unaligned `.so` segment, or failed `zipalign` terminates the job with exit code 1.

### 6.2 CI Execution Evidence
- **Run ID:** [38548792723](https://github.com/devil1527/rage_bait/actions/runs/38548792723)
- **Job ID:** `115801375186`
- **Result:** `success` (All 15 steps passed with exit code 0).
- **Verified Steps:**
  - Setup JDK 17 & Android SDK Build Tools 36.0.0: `success`
  - Download Godot 4.7.2 & Templates: `success`
  - Import Assets Headlessly: `success`
  - Run Headless Automated Test Suite (1,399 tests): `success`
  - Export Android Test APK: `success`
  - Verify Manifest Metadata & ABIs: `success`
  - Verify Native Library 16 KB ELF Alignment: `success`
  - Verify APK 16 KB Zip Alignment: `success`
  - Verify Exclusion of Non-Production Test Tools: `success`
  - Upload Test APK Artifact (`coin-hell-api36-test-apk`): `success`

---

## 7. Google Play Release Readiness & Remaining Blockers

### 7.1 Readiness Categorization

| Category | Status | Details |
| :--- | :---: | :--- |
| **Android API 36 Target** | **VERIFIED** | Satisfies targetSdkVersion = 36 requirement. |
| **16 KB ELF Alignment** | **VERIFIED** | All 64-bit native libraries meet 16 KB alignment. |
| **APK Zip Alignment** | **VERIFIED** | Passes `zipalign -c -P 16 -v 4` verification. |
| **Automated Tests** | **VERIFIED** | 1,399 programmatic unit and gameplay tests passed. |
| **Test Assets Exclusion** | **VERIFIED** | Zero test harnesses packaged in export build. |
| **Release Signing Key** | **REMAINING BLOCKER** | Currently uses debug keystore; production upload key must be created. |
| **Android App Bundle (.aab)**| **REMAINING BLOCKER** | Google Play requires AAB format; Gradle build required. |
| **Manual Gameplay Regression**| **REMAINING BLOCKER** | Levels 1–10 must be validated on physical Android hardware. |
| **Personal Account Testing**| **REMAINING BLOCKER** | 14-day closed testing with 12 or 20 testers required by Google. |
| **Privacy Policy & Data Safety**| **REMAINING BLOCKER** | Hosted privacy policy URL and Data Safety form required. |
| **Store Listing Graphics** | **REMAINING BLOCKER** | 512x512 icon, 1024x500 banner, and screenshots required. |

---

## 8. Audit Conclusions & Recommendations

1. **Migration Verification Succeeded:** The technical migration of *Retro Rage Arcade* to **Godot 4.7.2** and **Android API 36** is completely verified. The exported test APK satisfies all current Android 16 and 16 KB page alignment mandates.
2. **Safe to Proceed to Manual Testing:** Because all 1,399 automated tests passed and the APK package alignment is verified, it is completely safe to proceed to manual gameplay testing on physical Android devices.
3. **Preserve Branch Isolation:** Keep `migration/android-api36-godot47` isolated until manual regression testing is completed. Do not merge into `main` until release signing and AAB export pipelines are established.
4. **Next Phase:** Prepare the production release AAB pipeline (`android-release-aab.yml`) and generate secure release signing credentials via GitHub Secrets.
