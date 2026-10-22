# Local Environment Session for PowerShell
# Usage: . .\env.ps1 (Dot-source to apply to current session only)

$IOS_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$FLUTTER_ROOT = Join-Path $IOS_ROOT "flutter"
$TOOLS_BIN = Join-Path $IOS_ROOT "tools\bin"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Local Flutter iOS Workspace (D:\source\IOS)" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

if (Test-Path (Join-Path $FLUTTER_ROOT "bin")) {
    $env:PATH = "$(Join-Path $FLUTTER_ROOT 'bin');$TOOLS_BIN;$env:PATH"
    Write-Host "[OK] Local Flutter added to session PATH: $FLUTTER_ROOT" -ForegroundColor Green
} else {
    Write-Host "[!] Local Flutter not found in $FLUTTER_ROOT" -ForegroundColor Yellow
    Write-Host "    Run 'powershell -ExecutionPolicy Bypass -File tools\install-local-flutter.ps1' to install locally." -ForegroundColor Yellow
}

if (Test-Path $TOOLS_BIN) {
    if (-not ($env:PATH -split ';').Contains($TOOLS_BIN)) {
        $env:PATH = "$TOOLS_BIN;$env:PATH"
    }
    Write-Host "[OK] Local Tools added to session PATH: $TOOLS_BIN" -ForegroundColor Green
}

Write-Host "[OK] Session ready. Global environment was NOT modified." -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
