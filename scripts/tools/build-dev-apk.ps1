<#
.SYNOPSIS
    Exports a local Android development/debug APK for Retro Rage Arcade using Godot 4.7.2.

.DESCRIPTION
    Replaces GitHub Actions routine development APK builds on Windows.
    Reads existing Android SDK, JDK, NDK, and debug keystore configuration from
    Godot 4.7 EditorSettings (%APPDATA%\Godot\editor_settings-4.7.tres) and
    environment variables without inventing credentials or paths.

    Validates all required Android export dependencies before running Godot headless
    export ("Android" preset -> build\local\retro-rage-arcade-dev.apk), logs export
    diagnostics clearly, and never uploads anything to GitHub Actions.

.PARAMETER OutputApk
    Destination path for the exported APK. Defaults to build\local\retro-rage-arcade-dev.apk.

.PARAMETER PresetName
    Godot export preset name from export_presets.cfg. Defaults to "Android".

.PARAMETER GodotExe
    Optional path to Godot 4.7.2 console executable. Auto-detected if omitted.

.PARAMETER CheckOnly
    Validates local tooling and Godot Android export configuration without exporting.

.PARAMETER RunTests
    Runs the headless automated test suites before exporting the APK.

.PARAMETER SkipImport
    Skips the headless asset import refresh step before exporting.

.EXAMPLE
    .\scripts\tools\build-dev-apk.ps1 -CheckOnly
    .\scripts\tools\build-dev-apk.ps1
    .\scripts\tools\build-dev-apk.ps1 -RunTests
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputApk = "",

    [Parameter(Mandatory = $false)]
    [string]$PresetName = "Android",

    [Parameter(Mandatory = $false)]
    [string]$GodotExe = "",

    [Parameter(Mandatory = $false)]
    [switch]$CheckOnly,

    [Parameter(Mandatory = $false)]
    [switch]$RunTests,

    [Parameter(Mandatory = $false)]
    [switch]$SkipImport
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$OutputDir = Join-Path $RepoRoot "build\local"
if ([string]::IsNullOrWhiteSpace($OutputApk)) {
    $OutputApk = Join-Path $OutputDir "retro-rage-arcade-dev.apk"
} elseif (-not [System.IO.Path]::IsPathRooted($OutputApk)) {
    $OutputApk = Join-Path $RepoRoot $OutputApk
}
$OutputParentDir = Split-Path -Parent $OutputApk
$ExportLogPath = Join-Path $OutputParentDir "godot_export.log"

$EditorSettingsPath = Join-Path $env:APPDATA "Godot\editor_settings-4.7.tres"
$ExportTemplatesDir = Join-Path $env:APPDATA "Godot\export_templates\4.7.2.stable"
$AndroidBuildTemplateDir = Join-Path $RepoRoot "android\build"
$ExportPresetsPath = Join-Path $RepoRoot "export_presets.cfg"

$MissingItems = New-Object System.Collections.Generic.List[string]
$Warnings = New-Object System.Collections.Generic.List[string]

function Read-GodotEditorSettings {
    param ([string]$Path)
    $map = @{}
    if (-not (Test-Path -LiteralPath $Path)) {
        return $map
    }
    foreach ($line in (Get-Content -LiteralPath $Path -Encoding UTF8)) {
        if ($line -match '^\s*([a-zA-Z0-9_\/]+)\s*=\s*"(.*)"\s*$') {
            $key = $matches[1]
            # Unescape Godot string literal backslashes
            $val = $matches[2] -replace '\\\\', '\'
            $map[$key] = $val
        }
    }
    return $map
}

function Resolve-ConfigPath {
    param ([string]$PathValue)
    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return $PathValue
    }
    return ($PathValue -replace '/', '\')
}

function Resolve-GodotConsoleExe {
    param ([string]$RequestedPath)
    $candidates = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        $candidates.Add($RequestedPath)
    }
    foreach ($cmdName in @("Godot_v4.7.2-stable_win64_console.exe", "godot4.7", "godot")) {
        $cmd = Get-Command $cmdName -ErrorAction SilentlyContinue
        if ($cmd) {
            $candidates.Add($cmd.Source)
        }
    }
    $candidates.Add((Join-Path $env:USERPROFILE "godot\Godot_v4.7.2-stable_win64_console.exe"))
    $candidates.Add((Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links\Godot_v4.7.2-stable_win64_console.exe"))

    foreach ($cand in $candidates) {
        if (-not [string]::IsNullOrWhiteSpace($cand) -and (Test-Path -LiteralPath $cand)) {
            return $cand
        }
    }
    return $null
}

function Invoke-GodotStep {
    param (
        [string]$Executable,
        [string[]]$Arguments,
        [string]$LogFile
    )
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $Executable @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prevPref
    }
    if ($LogFile) {
        $output | Out-File -FilePath $LogFile -Encoding UTF8
    }
    return [PSCustomObject]@{
        ExitCode = $exitCode
        Output   = $output
    }
}

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "         RETRO RAGE ARCADE -- LOCAL WINDOWS DEV APK BUILD                 " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Repository : $RepoRoot"
Write-Host "Target APK : $OutputApk"
Write-Host ""

# -----------------------------------------------------------------------------
# 1. Verify Project & Export Preset Configuration
# -----------------------------------------------------------------------------
Write-Host "[1/6] Checking Godot project and export preset configuration..." -ForegroundColor Yellow

if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot "project.godot"))) {
    throw "project.godot not found in $RepoRoot"
}
if (-not (Test-Path -LiteralPath $ExportPresetsPath)) {
    throw "export_presets.cfg not found in $RepoRoot"
}

$presetContent = Get-Content -LiteralPath $ExportPresetsPath -Raw -Encoding UTF8
if ($presetContent -notmatch [regex]::Escape("name=`"$PresetName`"")) {
    throw "Export preset '$PresetName' was not found in $ExportPresetsPath"
}
$usesGradle = $presetContent -match 'gradle_build/use_gradle_build=true'
$targetSdk = if ($presetContent -match 'gradle_build/target_sdk="(\d+)"') { $matches[1] } else { "36" }
Write-Host "  [OK] Preset '$PresetName' found (Gradle build: $usesGradle, Target SDK: $targetSdk)" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 2. Verify Godot 4.7.2 Executable & Export Templates
# -----------------------------------------------------------------------------
Write-Host "[2/6] Checking Godot 4.7.2 executable and export templates..." -ForegroundColor Yellow

$ResolvedGodot = Resolve-GodotConsoleExe -RequestedPath $GodotExe
if (-not $ResolvedGodot) {
    $MissingItems.Add("Godot 4.7.2 console executable (Godot_v4.7.2-stable_win64_console.exe)")
    Write-Host "  [MISSING] Godot 4.7.2 console executable not found." -ForegroundColor Red
} else {
    $verResult = Invoke-GodotStep -Executable $ResolvedGodot -Arguments @("--version")
    $verString = ($verResult.Output | Select-Object -First 1) -as [string]
    if ($verString -notmatch '^4\.7\.2\.') {
        $Warnings.Add("Found Godot executable at '$ResolvedGodot' with version '$verString' (expected 4.7.2.*).")
        Write-Host "  [WARN] Godot version mismatch: $verString ($ResolvedGodot)" -ForegroundColor DarkYellow
    } else {
        Write-Host "  [OK] Godot $verString : $ResolvedGodot" -ForegroundColor Green
    }
}

if (-not (Test-Path -LiteralPath $ExportTemplatesDir)) {
    $MissingItems.Add("Godot 4.7.2 export templates at '$ExportTemplatesDir' (download Godot_v4.7.2-stable_export_templates.tpz)")
    Write-Host "  [MISSING] Export templates folder not found: $ExportTemplatesDir" -ForegroundColor Red
} else {
    $debugTemplateApk = Join-Path $ExportTemplatesDir "android_debug.apk"
    $androidSourceZip = Join-Path $ExportTemplatesDir "android_source.zip"
    if (-not (Test-Path -LiteralPath $debugTemplateApk) -or -not (Test-Path -LiteralPath $androidSourceZip)) {
        $MissingItems.Add("Android templates (android_debug.apk / android_source.zip) inside '$ExportTemplatesDir'")
        Write-Host "  [MISSING] Android export template files incomplete in $ExportTemplatesDir" -ForegroundColor Red
    } else {
        Write-Host "  [OK] Export templates found: $ExportTemplatesDir" -ForegroundColor Green
    }
}

if ($usesGradle) {
    if (-not (Test-Path -LiteralPath $AndroidBuildTemplateDir)) {
        $MissingItems.Add("Project Android Gradle build template at '$AndroidBuildTemplateDir' (install via Godot Editor: Project -> Install Android Build Template, or godot --headless --install-android-build-template)")
        Write-Host "  [MISSING] Android Gradle build template missing: $AndroidBuildTemplateDir" -ForegroundColor Red
    } else {
        Write-Host "  [OK] Android Gradle build template present: $AndroidBuildTemplateDir" -ForegroundColor Green
    }
}

# -----------------------------------------------------------------------------
# 3. Inspect Existing EditorSettings, JDK, Android SDK, NDK, and Keystore
# -----------------------------------------------------------------------------
Write-Host "[3/6] Checking JDK, Android SDK, NDK, and debug keystore configuration..." -ForegroundColor Yellow

$EditorSettings = Read-GodotEditorSettings -Path $EditorSettingsPath
if (-not (Test-Path -LiteralPath $EditorSettingsPath)) {
    $Warnings.Add("Godot EditorSettings not found at '$EditorSettingsPath'.")
    Write-Host "  [WARN] EditorSettings not found at $EditorSettingsPath" -ForegroundColor DarkYellow
} else {
    Write-Host "  [OK] Loaded EditorSettings: $EditorSettingsPath" -ForegroundColor Green
}

# JDK
$JavaSdkPath = Resolve-ConfigPath $EditorSettings["export/android/java_sdk_path"]
if ([string]::IsNullOrWhiteSpace($JavaSdkPath)) { $JavaSdkPath = Resolve-ConfigPath $env:JAVA_HOME }
if ([string]::IsNullOrWhiteSpace($JavaSdkPath) -or -not (Test-Path -LiteralPath (Join-Path $JavaSdkPath "bin\java.exe"))) {
    $MissingItems.Add("JDK 17 (checked EditorSettings 'export/android/java_sdk_path' and JAVA_HOME='$env:JAVA_HOME')")
    Write-Host "  [MISSING] JDK not found (configured: '$JavaSdkPath')" -ForegroundColor Red
} else {
    Write-Host "  [OK] JDK path: $JavaSdkPath" -ForegroundColor Green
}

# Android SDK
$AndroidSdkPath = Resolve-ConfigPath $EditorSettings["export/android/android_sdk_path"]
if ([string]::IsNullOrWhiteSpace($AndroidSdkPath)) { $AndroidSdkPath = Resolve-ConfigPath $env:ANDROID_HOME }
if ([string]::IsNullOrWhiteSpace($AndroidSdkPath)) { $AndroidSdkPath = Resolve-ConfigPath $env:ANDROID_SDK_ROOT }

$SdkValid = $false
if ([string]::IsNullOrWhiteSpace($AndroidSdkPath) -or -not (Test-Path -LiteralPath $AndroidSdkPath)) {
    $MissingItems.Add("Android SDK directory not found at configured path '$AndroidSdkPath' (install Android SDK with platforms;android-$targetSdk, build-tools;36.0.0, platform-tools, and cmdline-tools;latest)")
    Write-Host "  [MISSING] Android SDK directory missing: '$AndroidSdkPath'" -ForegroundColor Red
} else {
    $SdkValid = $true
    Write-Host "  [OK] Android SDK root: $AndroidSdkPath" -ForegroundColor Green

    $platformDir = Join-Path $AndroidSdkPath "platforms\android-$targetSdk"
    if (-not (Test-Path -LiteralPath $platformDir)) {
        $MissingItems.Add("Android SDK Platform $targetSdk ('$platformDir')")
        Write-Host "  [MISSING] Android SDK Platform $targetSdk missing: $platformDir" -ForegroundColor Red
    } else {
        Write-Host "  [OK] Android Platform $targetSdk present" -ForegroundColor Green
    }

    $buildToolsRoot = Join-Path $AndroidSdkPath "build-tools"
    $targetBuildTools = Join-Path $buildToolsRoot "$targetSdk.0.0"
    if (Test-Path -LiteralPath $targetBuildTools) {
        Write-Host "  [OK] Android Build Tools $targetSdk.0.0 present" -ForegroundColor Green
    } elseif ((Test-Path -LiteralPath $buildToolsRoot) -and (Get-ChildItem -LiteralPath $buildToolsRoot -Directory -ErrorAction SilentlyContinue)) {
        $foundBt = (Get-ChildItem -LiteralPath $buildToolsRoot -Directory | Select-Object -ExpandProperty Name) -join ", "
        $Warnings.Add("build-tools\$targetSdk.0.0 not found; available versions: $foundBt")
        Write-Host "  [WARN] build-tools\$targetSdk.0.0 missing (found: $foundBt)" -ForegroundColor DarkYellow
    } else {
        $MissingItems.Add("Android SDK Build Tools (e.g. build-tools;$targetSdk.0.0 under '$buildToolsRoot')")
        Write-Host "  [MISSING] Android SDK Build Tools missing under $buildToolsRoot" -ForegroundColor Red
    }

    $platformToolsDir = Join-Path $AndroidSdkPath "platform-tools"
    if (-not (Test-Path -LiteralPath (Join-Path $platformToolsDir "adb.exe"))) {
        $MissingItems.Add("Android SDK platform-tools (adb.exe under '$platformToolsDir')")
        Write-Host "  [MISSING] platform-tools missing inside SDK ($platformToolsDir)" -ForegroundColor Red
    } else {
        Write-Host "  [OK] Android platform-tools present" -ForegroundColor Green
    }
}

# Android NDK (optional for prebuilt Godot export templates, checked without inventing paths)
$NdkPath = Resolve-ConfigPath $EditorSettings["export/android/ndk_path"]
if ([string]::IsNullOrWhiteSpace($NdkPath)) { $NdkPath = Resolve-ConfigPath $env:ANDROID_NDK_HOME }
if ([string]::IsNullOrWhiteSpace($NdkPath)) { $NdkPath = Resolve-ConfigPath $env:ANDROID_NDK_ROOT }
if ([string]::IsNullOrWhiteSpace($NdkPath) -and $SdkValid) {
    $sdkNdkRoot = Join-Path $AndroidSdkPath "ndk"
    if (Test-Path -LiteralPath $sdkNdkRoot) {
        $firstNdk = Get-ChildItem -LiteralPath $sdkNdkRoot -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($firstNdk) { $NdkPath = $firstNdk.FullName }
    }
}
if ([string]::IsNullOrWhiteSpace($NdkPath) -or -not (Test-Path -LiteralPath $NdkPath)) {
    $Warnings.Add("Android NDK is not configured/installed locally. Precompiled Godot 4.7.2 export templates (android_source.zip) normally build without NDK, though Gradle/Android plugins may require NDK if native compilation is invoked.")
    Write-Host "  [INFO] Android NDK not configured/present (not required unless native compilation is triggered)" -ForegroundColor DarkYellow
} else {
    Write-Host "  [OK] Android NDK path: $NdkPath" -ForegroundColor Green
}

# Debug Keystore
$DebugKeystore = Resolve-ConfigPath $EditorSettings["export/android/debug_keystore"]
$DebugKeystorePass = $EditorSettings["export/android/debug_keystore_pass"]
if ([string]::IsNullOrWhiteSpace($DebugKeystore) -or -not (Test-Path -LiteralPath $DebugKeystore)) {
    $MissingItems.Add("Debug keystore configured in EditorSettings 'export/android/debug_keystore' ('$DebugKeystore')")
    Write-Host "  [MISSING] Debug keystore not found: '$DebugKeystore'" -ForegroundColor Red
} elseif ([string]::IsNullOrWhiteSpace($DebugKeystorePass)) {
    $MissingItems.Add("Debug keystore password in EditorSettings 'export/android/debug_keystore_pass'")
    Write-Host "  [MISSING] Debug keystore password not configured in EditorSettings" -ForegroundColor Red
} else {
    Write-Host "  [OK] Debug keystore present: $DebugKeystore" -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# Report missing dependencies or exit on CheckOnly
# -----------------------------------------------------------------------------
if ($MissingItems.Count -gt 0) {
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host "  EXPORT BLOCKED -- MISSING REQUIRED DEPENDENCIES ($($MissingItems.Count))" -ForegroundColor Red
    Write-Host "==========================================================================" -ForegroundColor Red
    foreach ($item in $MissingItems) {
        Write-Host "  - $item" -ForegroundColor Red
    }
    if ($Warnings.Count -gt 0) {
        Write-Host ""
        Write-Host "Warnings / Notes:" -ForegroundColor DarkYellow
        foreach ($w in $Warnings) {
            Write-Host "  - $w" -ForegroundColor DarkYellow
        }
    }
    Write-Host ""
    Write-Host "No files were uploaded or modified. Install the missing dependencies above and rerun." -ForegroundColor Gray
    exit 2
}

if ($CheckOnly) {
    Write-Host ""
    Write-Host "[CHECK ONLY] All required dependencies for local Android debug APK export are present." -ForegroundColor Green
    if ($Warnings.Count -gt 0) {
        foreach ($w in $Warnings) {
            Write-Host "  [WARN] $w" -ForegroundColor DarkYellow
        }
    }
    exit 0
}

# -----------------------------------------------------------------------------
# 4. Prepare Environment & Output Directory
# -----------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $OutputParentDir)) {
    New-Item -ItemType Directory -Path $OutputParentDir -Force | Out-Null
}
if (-not $env:JAVA_HOME -and $JavaSdkPath) {
    $env:JAVA_HOME = $JavaSdkPath
}
if (-not $env:ANDROID_HOME -and $AndroidSdkPath) {
    $env:ANDROID_HOME = $AndroidSdkPath
    $env:ANDROID_SDK_ROOT = $AndroidSdkPath
}

Push-Location $RepoRoot
try {
    # -------------------------------------------------------------------------
    # 5. Optional Asset Import & Headless Tests
    # -------------------------------------------------------------------------
    if (-not $SkipImport) {
        Write-Host "[4/6] Refreshing Godot headless asset imports..." -ForegroundColor Yellow
        $importLog = Join-Path $OutputParentDir "godot_import.log"
        $impRes = Invoke-GodotStep -Executable $ResolvedGodot -Arguments @("--headless", "--editor", "--quit") -LogFile $importLog
        if ($impRes.ExitCode -ne 0) {
            Write-Host "  [ERROR] Headless asset import failed (exit code $($impRes.ExitCode)). See $importLog" -ForegroundColor Red
            $impRes.Output | Select-Object -Last 40
            exit $impRes.ExitCode
        }
        Write-Host "  [OK] Asset import completed." -ForegroundColor Green
    } else {
        Write-Host "[4/6] Skipping headless asset import (--SkipImport)." -ForegroundColor Gray
    }

    if ($RunTests) {
        Write-Host "[5/6] Running headless automated test suites..." -ForegroundColor Yellow
        foreach ($testScene in @("res://scenes/tests/test_runner.tscn", "res://scenes/tests/bullet_betrayal_test_runner.tscn")) {
            Write-Host "  Running $testScene ..." -ForegroundColor Cyan
            $testLog = Join-Path $OutputParentDir ("test_" + [System.IO.Path]::GetFileNameWithoutExtension($testScene) + ".log")
            $testRes = Invoke-GodotStep -Executable $ResolvedGodot -Arguments @("--headless", $testScene) -LogFile $testLog
            if ($testRes.ExitCode -ne 0) {
                Write-Host "  [ERROR] Test suite failed ($testScene, exit code $($testRes.ExitCode)). See $testLog" -ForegroundColor Red
                $testRes.Output | Select-Object -Last 50
                exit $testRes.ExitCode
            }
            Write-Host "  [OK] Passed: $testScene" -ForegroundColor Green
        }
    } else {
        Write-Host "[5/6] Skipping test suites (pass -RunTests to execute before export)." -ForegroundColor Gray
    }

    # -------------------------------------------------------------------------
    # 6. Export Development/Debug APK
    # -------------------------------------------------------------------------
    Write-Host "[6/6] Exporting development/debug APK via preset '$PresetName'..." -ForegroundColor Yellow
    if (Test-Path -LiteralPath $OutputApk) {
        Remove-Item -LiteralPath $OutputApk -Force
    }

    $expRes = Invoke-GodotStep -Executable $ResolvedGodot -Arguments @(
        "--verbose",
        "--headless",
        "--export-debug",
        $PresetName,
        $OutputApk
    ) -LogFile $ExportLogPath

    if ($expRes.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $OutputApk)) {
        Write-Host ""
        Write-Host "==========================================================================" -ForegroundColor Red
        Write-Host "  GODOT ANDROID EXPORT FAILED (Exit Code: $($expRes.ExitCode))" -ForegroundColor Red
        Write-Host "==========================================================================" -ForegroundColor Red
        Write-Host "Full log saved to: $ExportLogPath" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "--- Key Error Lines ---" -ForegroundColor Red
        $errLines = $expRes.Output | Select-String -Pattern 'ERROR|FAILURE|Exception|Cannot|Missing|failed' | Select-Object -First 30
        if ($errLines) {
            $errLines | ForEach-Object { Write-Host $_.Line -ForegroundColor Red }
        } else {
            $expRes.Output | Select-Object -Last 40
        }
        exit ([Math]::Max($expRes.ExitCode, 1))
    }

    $apkInfo = Get-Item -LiteralPath $OutputApk
    if ($apkInfo.Length -lt 1000000) {
        Write-Host "  [ERROR] Exported APK is suspiciously small ($($apkInfo.Length) bytes). Check $ExportLogPath" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Green
    Write-Host "  LOCAL DEV APK EXPORT SUCCEEDED" -ForegroundColor Green
    Write-Host "==========================================================================" -ForegroundColor Green
    Write-Host "Output APK : $($apkInfo.FullName)"
    Write-Host ("APK Size   : {0:N2} MB ({1:N0} bytes)" -f ($apkInfo.Length / 1MB), $apkInfo.Length)
    Write-Host "Export Log : $ExportLogPath"
    Write-Host ""
    Write-Host "Optional ADB install command:" -ForegroundColor Cyan
    Write-Host "  `"$AndroidSdkPath\platform-tools\adb.exe`" install -r `"$($apkInfo.FullName)`""
} finally {
    Pop-Location
}
