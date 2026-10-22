# Flutter attach to iPhone via Wi-Fi (No Xcode required)
param (
    [Parameter(Mandatory=$false)]
    [string]$DebugUri
)

$IOS_ROOT = Split-Path -Parent $PSScriptRoot
$FLUTTER_EXE = Join-Path $IOS_ROOT "flutter\bin\flutter.bat"

if (-not (Test-Path $FLUTTER_EXE)) {
    $FLUTTER_EXE = "flutter"
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Flutter Attach via Wi-Fi (Windows -> iPhone)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "1. Ensure iPhone and this PC are on the same Wi-Fi subnet."
Write-Host "2. Launch the Debug-mode IPA on your iPhone."
Write-Host "3. Look for the console message on launch:"
Write-Host "   'The Dart VM Service is listening on http://192.168.x.x:PORT/TOKEN=/'"
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not $DebugUri) {
    $DebugUri = Read-Host "Paste the full Dart VM Service URL here"
}

if (-not $DebugUri) {
    Write-Host "[!] No URL provided. Aborting." -ForegroundColor Red
    exit 1
}

Write-Host ">>> Attaching Flutter to $DebugUri..." -ForegroundColor Green
Set-Location (Join-Path $IOS_ROOT "app")
& $FLUTTER_EXE attach --debug-uri=$DebugUri
