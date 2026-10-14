<#
.SYNOPSIS
    Creates a secure, production-ready Google Play upload keystore for Retro Rage Arcade.

.DESCRIPTION
    This script generates an RSA 2048-bit PKCS12 upload keystore with a 10,000-day validity.
    It prompts securely for passwords and publisher certificate identity, enforces storing
    the keystore outside the Git repository, refuses to overwrite existing keystores,
    and provides exact instructions for configuring GitHub Repository Secrets without
    exposing sensitive credentials.

.NOTES
    Application: Retro Rage Arcade (Coin Hell)
    Package ID:  com.antigravity.retroragearcade
    Engine:      Godot 4.7.2 / Android API 36
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$KeystoreDir = "$HOME\.retro-rage-release",

    [Parameter(Mandatory = $false)]
    [string]$KeystoreFileName = "retro-rage-upload-key.keystore",

    [Parameter(Mandatory = $false)]
    [string]$KeyAlias = "retro-rage-upload",

    [Parameter(Mandatory = $false)]
    [int]$ValidityDays = 10000,

    [Parameter(Mandatory = $false)]
    [int]$KeySize = 2048
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "      RETRO RAGE ARCADE -- PRODUCTION UPLOAD KEYSTORE GENERATOR            " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------------------------
# 1. Locate Java keytool utility
# -----------------------------------------------------------------------------
Write-Host "[1/6] Checking Java keytool availability..." -ForegroundColor Yellow

$KeytoolPath = $null

# Check PATH
$Cmd = Get-Command "keytool" -ErrorAction SilentlyContinue
if ($Cmd) {
    $KeytoolPath = $Cmd.Source
}

# Check JAVA_HOME if not found in PATH
if (-not $KeytoolPath -and $env:JAVA_HOME) {
    $Candidate = Join-Path $env:JAVA_HOME "bin\keytool.exe"
    if (Test-Path $Candidate) {
        $KeytoolPath = $Candidate
    }
}

# Check common Windows JDK directories
if (-not $KeytoolPath) {
    $CommonPaths = @(
        "C:\Program Files\Eclipse Adoptium\jdk-17*\bin\keytool.exe",
        "C:\Program Files\Java\jdk-17*\bin\keytool.exe",
        "C:\Program Files\Microsoft\jdk-17*\bin\keytool.exe",
        "G:\My Softs\jdk-17*\bin\keytool.exe"
    )
    foreach ($Pattern in $CommonPaths) {
        $Found = Get-ChildItem -Path $Pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($Found) {
            $KeytoolPath = $Found.FullName
            break
        }
    }
}

if (-not $KeytoolPath) {
    Write-Host "ERROR: Java 'keytool' executable could not be found!" -ForegroundColor Red
    Write-Host "Please ensure JDK 17 is installed and either:" -ForegroundColor Red
    Write-Host "  1. Add '<JDK_HOME>\bin' to your system PATH environment variable, or" -ForegroundColor Red
    Write-Host "  2. Set the JAVA_HOME environment variable (e.g. setx JAVA_HOME 'G:\My Softs\jdk-17')." -ForegroundColor Red
    exit 1
}

Write-Host "  [OK] Found keytool: $KeytoolPath" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 2. Validate Keystore Destination (Enforce outside Git repo)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "[2/6] Validating keystore destination..." -ForegroundColor Yellow

$RepoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$ResolvedTargetDir = [System.IO.Path]::GetFullPath($KeystoreDir)

if ($ResolvedTargetDir.StartsWith($RepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Host "SECURITY ERROR: The specified directory is INSIDE the Git repository:" -ForegroundColor Red
    Write-Host "  Target Dir: $ResolvedTargetDir" -ForegroundColor Red
    Write-Host "  Repo Root:  $RepoRoot" -ForegroundColor Red
    Write-Host "Production keystores must NEVER be stored inside the Git repository." -ForegroundColor Red
    Write-Host "Please use a directory outside the repository (default: $HOME\.retro-rage-release)." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ResolvedTargetDir)) {
    New-Item -ItemType Directory -Path $ResolvedTargetDir -Force | Out-Null
    Write-Host "  Created secure directory: $ResolvedTargetDir" -ForegroundColor Green
} else {
    Write-Host "  Using directory: $ResolvedTargetDir" -ForegroundColor Green
}

$FullKeystorePath = Join-Path $ResolvedTargetDir $KeystoreFileName

# -----------------------------------------------------------------------------
# 3. Check for existing keystore (Refuse to overwrite)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "[3/6] Checking for existing keystore..." -ForegroundColor Yellow

if (Test-Path $FullKeystorePath) {
    Write-Host "REFUSING TO OVERWRITE: A keystore already exists at:" -ForegroundColor Red
    Write-Host "  $FullKeystorePath" -ForegroundColor Red
    Write-Host "Overwriting an upload keystore permanently invalidates app updates." -ForegroundColor Red
    Write-Host "If you genuinely wish to recreate it, backup and remove the existing file first." -ForegroundColor Red
    exit 1
}

Write-Host "  [OK] Target keystore path is free: $FullKeystorePath" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 4. Prompt for Publisher Identity (Distinguished Name - dname)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "[4/6] Collecting publisher certificate identity..." -ForegroundColor Yellow
Write-Host "  This information identifies you as the publisher in the certificate." -ForegroundColor Gray
Write-Host "  It is embedded in the public certificate and visible in Google Play Console." -ForegroundColor Gray
Write-Host ""

$CN = ""
while ([string]::IsNullOrWhiteSpace($CN)) {
    $CN = Read-Host "  First and Last Name / Developer Name (e.g. Devil / Antigravity)"
}

$OU = Read-Host "  Organizational Unit (e.g. Mobile Gaming) [Default: Mobile Gaming]"
if ([string]::IsNullOrWhiteSpace($OU)) { $OU = "Mobile Gaming" }

$O = Read-Host "  Organization Name (e.g. Retro Rage Arcade) [Default: Retro Rage Arcade]"
if ([string]::IsNullOrWhiteSpace($O)) { $O = "Retro Rage Arcade" }

$L = Read-Host "  City or Locality [Default: Bengaluru]"
if ([string]::IsNullOrWhiteSpace($L)) { $L = "Bengaluru" }

$ST = Read-Host "  State or Province [Default: Karnataka]"
if ([string]::IsNullOrWhiteSpace($ST)) { $ST = "Karnataka" }

$C = ""
while ($C.Length -ne 2) {
    $C = (Read-Host "  Two-letter Country Code (e.g. IN / US / GB)").Trim().ToUpper()
    if ($C.Length -ne 2) {
        Write-Host "    Country code must be exactly 2 letters (ISO 3166-1 alpha-2)." -ForegroundColor Red
    }
}

$DName = "CN=$CN, OU=$OU, O=$O, L=$L, ST=$ST, C=$C"
Write-Host "  Constructed Distinguished Name: $DName" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# 5. Prompt for Passwords Securely
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "[5/6] Setting secure passwords..." -ForegroundColor Yellow
Write-Host "  Passwords must be at least 8 characters long. Input is masked." -ForegroundColor Gray
Write-Host ""

function Prompt-SecurePassword([string]$PromptText) {
    while ($true) {
        $Pass1 = Read-Host "$PromptText" -AsSecureString
        $BSTR1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Pass1)
        $Plain1 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR1)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR1)

        if ($Plain1.Length -lt 8) {
            Write-Host "  Error: Password must be at least 8 characters long." -ForegroundColor Red
            continue
        }

        $Pass2 = Read-Host "Confirm password" -AsSecureString
        $BSTR2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Pass2)
        $Plain2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR2)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR2)

        if ($Plain1 -ne $Plain2) {
            Write-Host "  Error: Passwords do not match. Please try again." -ForegroundColor Red
            continue
        }

        return $Plain1
    }
}

$StorePassword = Prompt-SecurePassword "Enter Keystore Password (storepass)"

$SameKeyPass = Read-Host "Use same password for the private key? (Standard for PKCS12) [Y/n]"
if ([string]::IsNullOrWhiteSpace($SameKeyPass) -or $SameKeyPass.Trim().ToLower() -eq 'y') {
    $KeyPassword = $StorePassword
} else {
    $KeyPassword = Prompt-SecurePassword "Enter Key Password (keypass)"
}

# -----------------------------------------------------------------------------
# 6. Generate the Keystore using keytool
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "[6/6] Generating RSA 2048-bit PKCS12 upload keystore..." -ForegroundColor Yellow

$KeytoolArgs = @(
    "-genkeypair",
    "-alias", "`"$KeyAlias`"",
    "-keyalg", "RSA",
    "-keysize", $KeySize.ToString(),
    "-validity", $ValidityDays.ToString(),
    "-keystore", "`"$FullKeystorePath`"",
    "-storetype", "PKCS12",
    "-dname", "`"$DName`"",
    "-storepass", "`"$StorePassword`"",
    "-keypass", "`"$KeyPassword`"",
    "-v"
)

try {
    $Process = Start-Process -FilePath $KeytoolPath -ArgumentList $KeytoolArgs -NoNewWindow -Wait -PassThru
    if ($Process.ExitCode -ne 0) {
        throw "keytool process exited with code $($Process.ExitCode)"
    }
} catch {
    Write-Host "ERROR: Failed to generate keystore: $_" -ForegroundColor Red
    $StorePassword = $null
    $KeyPassword = $null
    [System.GC]::Collect()
    exit 1
}

# Clear plain text passwords from memory immediately
$StorePassword = $null
$KeyPassword = $null
[System.GC]::Collect()

if (-not (Test-Path $FullKeystorePath)) {
    Write-Host "ERROR: Keystore file was not created at expected path: $FullKeystorePath" -ForegroundColor Red
    exit 1
}

$FileInfo = Get-Item $FullKeystorePath
Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "            KEYSTORE SUCCESSFULLY GENERATED!                              " -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "  Keystore File:  $($FileInfo.FullName)" -ForegroundColor Cyan
Write-Host "  File Size:      $($FileInfo.Length) bytes" -ForegroundColor Cyan
Write-Host "  Key Alias:      $KeyAlias" -ForegroundColor Cyan
Write-Host "  Algorithm:      RSA $KeySize-bit" -ForegroundColor Cyan
Write-Host "  Validity:       $ValidityDays days (~27 years)" -ForegroundColor Cyan
Write-Host "  Format:         PKCS12" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------------------------
# 7. Backup and Security Guidance
# -----------------------------------------------------------------------------
Write-Host "IMPORTANT BACKUP & SECURITY NOTICE:" -ForegroundColor Yellow
Write-Host "1. WHY BACKING UP THIS KEYSTORE IS CRITICAL:" -ForegroundColor Gray
Write-Host "   - This keystore is your Google Play Upload Key." -ForegroundColor Gray
Write-Host "   - When you publish your app on Google Play, Google verifies that every" -ForegroundColor Gray
Write-Host "     App Bundle update (.aab) is signed with this exact key." -ForegroundColor Gray
Write-Host "   - If you lose this keystore or forget the passwords, you will be unable" -ForegroundColor Gray
Write-Host "     to update Retro Rage Arcade without requesting an Upload Key Reset from" -ForegroundColor Gray
Write-Host "     Google Play Developer Support, causing publishing delays." -ForegroundColor Gray
Write-Host "" -ForegroundColor Gray
Write-Host "2. HOW TO BACK UP SAFELY:" -ForegroundColor Gray
Write-Host "   - Make an encrypted backup copy of '$($FileInfo.FullName)' immediately." -ForegroundColor Gray
Write-Host "   - Store the backup in a secure offline location (e.g. BitLocker or encrypted USB)." -ForegroundColor Gray
Write-Host "   - Store passwords and key alias ('$KeyAlias') in your password manager." -ForegroundColor Gray
Write-Host "   - NEVER commit the keystore file or passwords to any Git repository." -ForegroundColor Gray
Write-Host ""

Write-Host "GITHUB SECRETS CONFIGURATION INSTRUCTIONS:" -ForegroundColor Yellow
Write-Host "To use this keystore in the automated GitHub Actions release workflow (.github/workflows/android-release-aab.yml)," -ForegroundColor Gray
Write-Host "you will configure 4 GitHub Repository Secrets:" -ForegroundColor Gray
Write-Host ""
Write-Host "  1. ANDROID_RELEASE_KEY_ALIAS" -ForegroundColor White
Write-Host "     Value: $KeyAlias" -ForegroundColor Cyan
Write-Host "  2. ANDROID_RELEASE_KEYSTORE_PASSWORD" -ForegroundColor White
Write-Host "     Value: <The keystore password you just entered>" -ForegroundColor Cyan
Write-Host "  3. ANDROID_RELEASE_KEY_PASSWORD" -ForegroundColor White
Write-Host "     Value: <The private key password you just entered>" -ForegroundColor Cyan
Write-Host "  4. ANDROID_RELEASE_KEYSTORE_BASE64" -ForegroundColor White
Write-Host "     Value: <The Base64 string of your keystore file>" -ForegroundColor Cyan
Write-Host ""
Write-Host "To safely copy the Base64 string of your keystore to your clipboard without printing it to the screen, run:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [Convert]::ToBase64String([IO.File]::ReadAllBytes('$($FileInfo.FullName)')) | Set-Clipboard" -ForegroundColor Green
Write-Host ""
Write-Host "Then navigate to:" -ForegroundColor Gray
Write-Host "  GitHub Repository -> Settings -> Secrets and variables -> Actions -> 'New repository secret'" -ForegroundColor Gray
Write-Host "and paste the clipboard contents as ANDROID_RELEASE_KEYSTORE_BASE64." -ForegroundColor Gray
Write-Host "==========================================================================" -ForegroundColor Green
