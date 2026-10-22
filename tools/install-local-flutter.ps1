# Downloads and extracts official Flutter SDK Stable directly into D:\source\IOS\flutter
# Completely self-contained - DOES NOT touch global system or registry.

$ErrorActionPreference = "Stop"
$IOS_ROOT = Split-Path -Parent $PSScriptRoot
$FLUTTER_DEST = Join-Path $IOS_ROOT "flutter"
$TEMP_DIR = Join-Path $IOS_ROOT "tools\temp"

if (Test-Path (Join-Path $FLUTTER_DEST "bin\flutter.bat")) {
    Write-Host "[OK] Flutter is already installed at: $FLUTTER_DEST" -ForegroundColor Green
    & (Join-Path $FLUTTER_DEST "bin\flutter.bat") --version
    exit 0
}

Write-Host ">>> Fetching latest Flutter stable release metadata..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $TEMP_DIR | Out-Null

$releasesUrl = "https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json"
$releasesJson = Invoke-RestMethod -Uri $releasesUrl -UseBasicParsing

$currentHash = $releasesJson.current_release.stable
$releaseObj = $releasesJson.releases | Where-Object { $_.hash -eq $currentHash } | Select-Object -First 1

if (-not $releaseObj) {
    Write-Host "[!] Could not determine current stable release, falling back to 3.24.5 default..." -ForegroundColor Yellow
    $archiveUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"
    $archiveName = "flutter_windows_3.24.5-stable.zip"
} else {
    $archiveUrl = "https://storage.googleapis.com/flutter_infra_release/releases/$($releaseObj.archive)"
    $archiveName = Split-Path -Leaf $releaseObj.archive
    Write-Host "[OK] Found Flutter version: $($releaseObj.version) ($archiveName)" -ForegroundColor Green
}

$zipPath = Join-Path $TEMP_DIR $archiveName

if (-not (Test-Path $zipPath)) {
    Write-Host ">>> Downloading Flutter SDK archive to $zipPath..." -ForegroundColor Cyan
    Write-Host "    Source: $archiveUrl"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Start-BitsTransfer -Source $archiveUrl -Destination $zipPath -DisplayName "Downloading Flutter" -Description "Flutter SDK for D:\source\IOS"
}

Write-Host ">>> Extracting Flutter SDK to $IOS_ROOT..." -ForegroundColor Cyan
Expand-Archive -Path $zipPath -DestinationPath $IOS_ROOT -Force

Write-Host ">>> Cleaning up temporary zip..." -ForegroundColor Cyan
Remove-Item -Path $TEMP_DIR -Recurse -Force

Write-Host ">>> Initializing local Flutter SDK..." -ForegroundColor Cyan
$flutterExe = Join-Path $FLUTTER_DEST "bin\flutter.bat"
& $flutterExe --version

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " [SUCCESS] Local Flutter SDK installed at: $FLUTTER_DEST" -ForegroundColor Green
Write-Host " To start using it, run '.\env.bat' or '. .\env.ps1' in this directory." -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
