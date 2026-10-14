# ANDROID API 36 & 16 KB PAGE-SIZE COMPLIANCE AUDIT
## Retro Rage Arcade — Technical Verification Report

---

| Audit Attribute | Value |
| :--- | :--- |
| **Application Package ID** | `com.antigravity.retroragearcade` |
| **Target Android API Level** | `36` (Android 16 / Baklava) |
| **Minimum Android API Level** | `24` (Android 7.0 / Nougat) |
| **Version Code / Name** | `10` / `0.10.0` |
| **Audit Date** | October 14, 2026 |
| **Tested Build Artifact** | `build/coin-hell-api36-test.apk` (SHA-256: `9fa0670868822097034c2bb91f274cbba1a64f331cf5d8ba0b92db2c027411bb`) |
| **CI Build Execution** | GitHub Actions Run `#38548792723`, Job `#115801375186` |
| **Engine & Export Template** | Godot Engine `v4.7.2.stable.official.ed1daf0bf` |
| **Compliance Status** | **100% COMPLIANT** (All 4 libraries verified; zipalign verified) |

---

## 1. Regulatory Context & Official Google Play Mandates

### 1.1 Android API 36 Target SDK Policy
- **Requirement:** Google Play requires new applications and major updates to target recent Android API levels to ensure modern security boundaries, runtime permission enforcement, and platform optimizations.
- **Android API 36 Specification:** API 36 represents Android 16. Targeting API 36 ensures full forward-compatibility with future Google Play target SDK enforcement cycles.
- **Official Policy URL:** [https://developer.android.com/google/play/requirements/target-sdk](https://developer.android.com/google/play/requirements/target-sdk)
- **Date Checked:** October 14, 2026.

### 1.2 16 KB Page-Size Kernel Compatibility Mandate
- **Requirement:** Historically, Android devices uniformly configured ARM64 kernels with 4 KB physical memory pages ($4096\text{ bytes}$). Beginning with Android 15 and expanding aggressively in Android 16, Google and OEM device manufacturers have introduced devices configured with **16 KB memory pages** ($16384\text{ bytes}$) to improve application launch speeds, reduce power consumption, and optimize camera and GPU memory pipelines.
- **Release-Blocking Constraint:** Google Play mandates that any native shared object (`.so`) packaged within 64-bit architectures (`arm64-v8a`, `x86_64`) must be compiled with an ELF `PT_LOAD` segment alignment of at least 16 KB (`-Wl,-z,max-page-size=16384`). If an application contains unaligned 64-bit native libraries, it will experience instant runtime crashes (`SIGSEGV` / `Invalid address alignment`) when loaded by the dynamic linker on 16 KB kernel devices.
- **32-Bit Legacy Architecture Exception:** Devices utilizing 32-bit legacy architectures (`armeabi-v7a`, `x86`) do not support 16 KB memory page kernels and remain restricted to standard 4 KB boundaries (`0x1000`). Google Play's 16 KB requirement applies strictly to 64-bit binaries.
- **Official Guidance URL:** [https://developer.android.com/guide/practices/page-sizes](https://developer.android.com/guide/practices/page-sizes)
- **Date Checked:** October 14, 2026.

---

## 2. Package Identity & Manifest Verification

### 2.1 Verification Tool & Command
The exported APK was inspected using the official Android SDK Build Tools 36.0.0 `aapt2` utility:
```bash
$ANDROID_HOME/build-tools/36.0.0/aapt2 dump badging build/coin-hell-api36-test.apk
```

### 2.2 Extracted Manifest Properties vs Expected Values

| Manifest Field | Configured / Expected | Actual APK Manifest Value | Status |
| :--- | :--- | :--- | :---: |
| **Package Name** | `com.antigravity.retroragearcade` | `com.antigravity.retroragearcade` | **PASS** |
| **Version Code** | `10` | `10` | **PASS** |
| **Version Name** | `0.10.0` | `0.10.0` | **PASS** |
| **Target SDK Version** | `36` | `36` | **PASS** |
| **Minimum SDK Version** | `24` | `24` | **PASS** |
| **Packaged Native ABIs** | `arm64-v8a`, `armeabi-v7a` | `arm64-v8a`, `armeabi-v7a` | **PASS** |
| **Application Label** | `Retro Rage Arcade` | `Retro Rage Arcade` | **PASS** |
| **Screen Orientation** | Landscape (`0`) | `landscape` | **PASS** |
| **Hardware Features** | Landscape touch | `android.hardware.screen.landscape`, `android.hardware.touchscreen` | **PASS** |
| **Supported Screens** | `small`, `normal`, `large`, `xlarge` | `small='true'`, `normal='true'`, `large='true'`, `xlarge='true'` | **PASS** |
| **Declared Permissions** | None requested | Zero permissions requested | **PASS** |

### 2.3 Raw Manifest Badging Excerpt
```text
package: name='com.antigravity.retroragearcade' versionCode='10' versionName='0.10.0' compileSdkVersion='36' compileSdkVersionCodename='16'
sdkVersion:'24'
targetSdkVersion:'36'
uses-feature: name='android.hardware.screen.landscape'
uses-feature: name='android.hardware.touchscreen'
supports-screens: 'small' 'normal' 'large' 'xlarge'
locales: '--_--'
densities: '120' '160' '240' '320' '480' '640'
native-code: 'arm64-v8a' 'armeabi-v7a'
```

---

## 3. Native Library 16 KB ELF Alignment Verification

### 3.1 Verification Methodology & Tooling
To guarantee zero release blockers, **every native library across every packaged ABI** was extracted and inspected:
- **Extraction Command:** `unzip -q build/coin-hell-api36-test.apk -d /tmp/apk_unpacked`
- **Inspection Tool:** GNU `readelf` (Ubuntu 24.04 Linux, GNU readelf version 2.42).
- **Inspection Command:** `readelf -lW <path_to_so_file>`
- **Mathematical Alignment Rule:**
  - An ELF `PT_LOAD` segment is aligned for page size $P$ if and only if:
    1. The segment alignment field `Align` is greater than or equal to $P$ (`Align >= 0x4000` for 16 KB).
    2. The virtual address (`p_vaddr`) and file offset (`p_offset`) satisfy:
       $$(p\_vaddr - p\_offset) \pmod P = 0$$

### 3.2 Full Native Library Inventory
The APK packages exactly **4 native shared libraries** across 2 architectures:
1. `lib/arm64-v8a/libc++_shared.so` (LLVM libc++ runtime for AArch64)
2. `lib/arm64-v8a/libgodot_android.so` (Godot 4.7.2 Engine Core for AArch64)
3. `lib/armeabi-v7a/libc++_shared.so` (LLVM libc++ runtime for 32-bit ARM)
4. `lib/armeabi-v7a/libgodot_android.so` (Godot 4.7.2 Engine Core for 32-bit ARM)

### 3.3 Detailed Segment Inspection Results

```
=========================================================================================================
Library Path                               ABI          Seg  Offset       VirtAddr       Align      Result
=========================================================================================================
lib/arm64-v8a/libc++_shared.so             arm64-v8a    0    0x0          0x0            0x4000     PASS (16 KB - 0x4000)
lib/arm64-v8a/libc++_shared.so             arm64-v8a    1    0xcd850      0xdd850        0x4000     PASS (16 KB - 0x4000)
lib/arm64-v8a/libc++_shared.so             arm64-v8a    2    0xdf028      0xf3028        0x4000     PASS (16 KB - 0x4000)
---------------------------------------------------------------------------------------------------------
lib/arm64-v8a/libgodot_android.so          arm64-v8a    0    0x0          0x0            0x4000     PASS (16 KB - 0x4000)
lib/arm64-v8a/libgodot_android.so          arm64-v8a    1    0x2b388d8    0x2b4c8d8      0x4000     PASS (16 KB - 0x4000)
lib/arm64-v8a/libgodot_android.so          arm64-v8a    2    0x3cbe540    0x3cd6540      0x4000     PASS (16 KB - 0x4000)
---------------------------------------------------------------------------------------------------------
lib/armeabi-v7a/libc++_shared.so           armeabi-v7a  0    0x0          0x0            0x1000     PASS (32-bit 4 KB - 0x1000)
lib/armeabi-v7a/libc++_shared.so           armeabi-v7a  1    0xaba0c      0xada0c        0x1000     PASS (32-bit 4 KB - 0x1000)
lib/armeabi-v7a/libc++_shared.so           armeabi-v7a  2    0xb6558      0xb9558        0x1000     PASS (32-bit 4 KB - 0x1000)
---------------------------------------------------------------------------------------------------------
lib/armeabi-v7a/libgodot_android.so        armeabi-v7a  0    0x0          0x0            0x1000     PASS (32-bit 4 KB - 0x1000)
lib/armeabi-v7a/libgodot_android.so        armeabi-v7a  1    0x21bb468    0x21bd468      0x1000     PASS (32-bit 4 KB - 0x1000)
lib/armeabi-v7a/libgodot_android.so        armeabi-v7a  2    0x2e8f1ec    0x2e921ec      0x1000     PASS (32-bit 4 KB - 0x1000)
=========================================================================================================
```

### 3.4 Mathematical Alignment Proofs (64-Bit Binaries)

#### Library: `lib/arm64-v8a/libgodot_android.so`
- **Segment 0 (Text / Code Segment):**
  - Offset = `0x0`, VirtAddr = `0x0`, Align = `0x4000` ($16384\text{ bytes}$).
  - $(0 - 0) \pmod{16384} = 0 \implies \mathbf{PASS}$.
- **Segment 1 (Read-Only Data Segment):**
  - Offset = `0x2b388d8` ($45320408$), VirtAddr = `0x2b4c8d8` ($45402328$), Align = `0x4000` ($16384$).
  - $(45402328 - 45320408) = 81920\text{ bytes}$.
  - $81920 \pmod{16384} = 5 \times 16384 - 81920 = 0 \implies \mathbf{PASS}$.
- **Segment 2 (Data / BSS Segment):**
  - Offset = `0x3cbe540` ($63694144$), VirtAddr = `0x3cd6540` ($63792448$), Align = `0x4000` ($16384$).
  - $(63792448 - 63694144) = 98304\text{ bytes}$.
  - $98304 \pmod{16384} = 6 \times 16384 - 98304 = 0 \implies \mathbf{PASS}$.

#### Library: `lib/arm64-v8a/libc++_shared.so`
- **Segment 0:** Offset = `0x0`, VirtAddr = `0x0`, Align = `0x4000` $\implies \mathbf{PASS}$.
- **Segment 1:** Offset = `0xcd850` ($841808$), VirtAddr = `0xdd850` ($907344$).
  - $(907344 - 841808) = 65536\text{ bytes} = 4 \times 16384$.
  - $65536 \pmod{16384} = 0 \implies \mathbf{PASS}$.
- **Segment 2:** Offset = `0xdf028` ($913448$), VirtAddr = `0xf3028` ($995368$).
  - $(995368 - 913448) = 81920\text{ bytes} = 5 \times 16384$.
  - $81920 \pmod{16384} = 0 \implies \mathbf{PASS}$.

---

## 4. Android SDK `zipalign` 16 KB Page Verification

### 4.1 Requirement & Alignment Rule
Even when native ELF binaries are compiled with 16 KB page-size compatibility, the Android package manager cannot map `.so` files directly from the APK archive into memory (`mmap`) unless the files are stored **uncompressed** and aligned at an offset within the zip archive that is a multiple of **16 KB** ($16384\text{ bytes}$).

### 4.2 Verification Tool & Command
The official Android SDK Build Tools 36.0.0 `zipalign` utility was executed in the CI pipeline:
```bash
$ANDROID_HOME/build-tools/36.0.0/zipalign -c -P 16 -v 4 build/coin-hell-api36-test.apk
```
- `-c`: Check alignment only (verifies whether archive satisfies requirements without mutating).
- `-P 16`: Enforces page alignment of $16\text{ KB}$ ($16 \times 1024 = 16384\text{ bytes}$) on shared object files.
- `-v 4`: Verbose output with standard 4-byte alignment on metadata and resource files.

### 4.3 Command Execution Evidence
- **Exit Code:** `0`
- **Output Excerpt:**
  ```text
  === RUNNING ANDROID SDK ZIPALIGN 16 KB VERIFICATION ===
  Using zipalign binary: /usr/local/lib/android/sdk/build-tools/36.0.0/zipalign
  Executing command: zipalign -c -P 16 -v 4 build/coin-hell-api36-test.apk
  Verifying alignment of build/coin-hell-api36-test.apk (4)...
        51 res/drawable-xxxhdpi-v4/icon.png (OK - compressed)
       861 res/drawable-xxhdpi-v4/icon.png (OK - compressed)
      1473 res/drawable-xhdpi-v4/icon.png (OK - compressed)
      1984 res/drawable-hdpi-v4/icon.png (OK - compressed)
      2429 res/drawable-mdpi-v4/icon.png (OK - compressed)
      2779 AndroidManifest.xml (OK - compressed)
      4013 resources.arsc (OK)
     16384 lib/arm64-v8a/libc++_shared.so (OK)
    999424 lib/arm64-v8a/libgodot_android.so (OK)
  64585728 lib/armeabi-v7a/libc++_shared.so (OK)
  65355776 lib/armeabi-v7a/libgodot_android.so (OK)
  114409472 classes.dex (OK - compressed)
  Verification succesful
  ==========================================
  zipalign exit code: 0
  ==========================================
  SUCCESS: APK satisfies Android 16 KB zip alignment requirements!
  ```
- **Zip Alignment Proof:**
  - `lib/arm64-v8a/libc++_shared.so` offset: `16384` ($16384 \pmod{16384} = 0$).
  - `lib/arm64-v8a/libgodot_android.so` offset: `999424` ($999424 / 16384 = 61.0$).
  - `lib/armeabi-v7a/libc++_shared.so` offset: `64585728` ($64585728 / 16384 = 3942.0$).
  - `lib/armeabi-v7a/libgodot_android.so` offset: `65355776` ($65355776 / 16384 = 3989.0$).
- **Verdict:** Every uncompressed native library is aligned at an exact multiple of 16 KB.

---

## 5. Non-Production Resource Exclusion Verification

### 5.1 Security & Packaging Policy
To ensure production packages do not ship test scenes, test runners, capture scripts, or debug assets, `export_presets.cfg` mandates:
```ini
exclude_filter="scenes/tests/*, scripts/tests/*, scripts/tools/*, screenshots/*"
```

### 5.2 Verification Command & Result
In GitHub Actions Job `#115801375186`:
```bash
unzip -l build/coin-hell-api36-test.apk | grep -E "scenes/tests|scripts/tests|scripts/tools|screenshots"
```
- **Matches Found:** `0`
- **Exit Code:** `1` (grep found no matches, confirming total exclusion)
- **Verdict:** Test harnesses, test runners, and developer capture tools are strictly absent from the packaged APK.

---

## 6. Official Sign-Off & Verdict

```
+------------------------------------------------------------------------------------+
|                      ANDROID API 36 / 16 KB COMPLIANCE SUMMARY                     |
+-----------------------------------------------------------------+------------------+
| Verification Item                                               | Final Result     |
+-----------------------------------------------------------------+------------------+
| Target SDK 36 (Android 16) Manifest Declaration                 | VERIFIED / PASS  |
| Minimum SDK 24 (Android 7.0) Compatibility                      | VERIFIED / PASS  |
| Package ID: com.antigravity.retroragearcade                     | VERIFIED / PASS  |
| Version Code: 10 / Version Name: 0.10.0                         | VERIFIED / PASS  |
| 64-Bit ELF LOAD Alignment (libgodot_android.so arm64-v8a)       | VERIFIED / PASS  |
| 64-Bit ELF LOAD Alignment (libc++_shared.so arm64-v8a)          | VERIFIED / PASS  |
| 32-Bit Legacy ELF LOAD Alignment (armeabi-v7a binaries)         | VERIFIED / PASS  |
| Android SDK zipalign 16 KB Archive Verification (-P 16)         | VERIFIED / PASS  |
| Non-Production Test Resource Exclusion                          | VERIFIED / PASS  |
+-----------------------------------------------------------------+------------------+
| FINAL COMPLIANCE VERDICT                                        | 100% COMPLIANT   |
+-----------------------------------------------------------------+------------------+
```
