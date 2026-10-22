# Flutter attach to iPhone via USB Cable using local iproxy (No Xcode required)
param (
    [int]$LocalPort = 8181,
    [int]$DevicePort = 8181,
    [string]$AuthToken = ""
)

$IOS_ROOT = Split-Path -Parent $PSScriptRoot
$IPROXY_EXE = Join-Path $IOS_ROOT "tools\bin\iproxy.exe"
$FLUTTER_EXE = Join-Path $IOS_ROOT "flutter\bin\flutter.bat"

if (-not (Test-Path $FLUTTER_EXE)) {
    $FLUTTER_EXE = "flutter"
}

if (-not (Test-Path $IPROXY_EXE)) {
    Write-Host "[!] iproxy.exe not found at $IPROXY_EXE" -ForegroundColor Yellow
    Write-Host "    Run 'powershell tools\install-local-tools.ps1' to download it locally." -ForegroundColor Yellow
    exit 1
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Flutter Attach via USB Cable (Windows -> iPhone)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "1. Connect iPhone to PC via Lightning/USB-C cable."
Write-Host "2. Ensure 'Trust This Computer' is accepted on iPhone."
Write-Host "3. Ensure iTunes (Apple Standalone) has AMDS driver running."
Write-Host "==========================================================" -ForegroundColor Cyan

# Start iproxy in background job
Write-Host ">>> Starting iproxy background job (Local Port: $LocalPort -> Device Port: $DevicePort)..." -ForegroundColor Cyan
$proxyJob = Start-Job -ScriptBlock {
    param($exe, $lport, $dport)
    & $exe $lport $dport
} -ArgumentList $IPROXY_EXE, $LocalPort, $DevicePort

Start-Sleep -Seconds 2

if ($proxyJob.State -ne "Running") {
    Write-Host "[!] iproxy failed to start. Is your iPhone plugged in and trusted?" -ForegroundColor Red
    Receive-Job $proxyJob
    Remove-Job $proxyJob -Force
    exit 1
}

Write-Host "[OK] Port forwarding active." -ForegroundColor Green

if (-not $AuthToken) {
    Write-Host "Enter the auth token from app launch if prompted (e.g. /ws or /token=xxx), or press Enter for default:" -ForegroundColor Yellow
    $AuthToken = Read-Host "Auth Token (Optional)"
}

$targetUri = "http://127.0.0.1:$LocalPort/$AuthToken"
Write-Host ">>> Attaching Flutter to $targetUri..." -ForegroundColor Green

try {
    Set-Location (Join-Path $IOS_ROOT "app")
    & $FLUTTER_EXE attach --debug-uri=$targetUri
} finally {
    Write-Host ">>> Stopping iproxy port forwarder..." -ForegroundColor Cyan
    Stop-Job $proxyJob -ErrorAction SilentlyContinue
    Remove-Job $proxyJob -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Cleaned up." -ForegroundColor Green
}
