# Downloads standalone Windows port of libimobiledevice and jitterbugpair
# Installs directly into D:\source\IOS\tools\bin - zero global changes.

$ErrorActionPreference = "Stop"
$IOS_ROOT = Split-Path -Parent $PSScriptRoot
$BIN_DIR = Join-Path $IOS_ROOT "tools\bin"
$TEMP_DIR = Join-Path $IOS_ROOT "tools\temp"

New-Item -ItemType Directory -Force -Path $BIN_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $TEMP_DIR | Out-Null

Write-Host ">>> Preparing local tools directory at $BIN_DIR..." -ForegroundColor Cyan

# 1. Download libimobiledevice prebuilt win64
$libimobileUrl = "https://github.com/libimobiledevice-win32/imobiledevice-net/releases/download/v1.3.17/imobiledevice-x64.zip"
$libimobileZip = Join-Path $TEMP_DIR "libimobiledevice.zip"

try {
    Write-Host ">>> Downloading libimobiledevice (iproxy, idevicecrashreport)..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $libimobileUrl -OutFile $libimobileZip -UseBasicParsing
    Expand-Archive -Path $libimobileZip -DestinationPath $BIN_DIR -Force
    Write-Host "[OK] libimobiledevice installed to $BIN_DIR" -ForegroundColor Green
} catch {
    Write-Host "[!] Could not auto-download libimobiledevice: $_" -ForegroundColor Yellow
    Write-Host "    You can manually place iproxy.exe, idevicecrashreport.exe into $BIN_DIR" -ForegroundColor Yellow
}

# 2. Download jitterbugpair (for SideStore pairing file generation)
$jitterbugUrl = "https://github.com/osy/Jitterbug/releases/download/v1.3.1/jitterbugpair-win64.zip"
$jitterbugZip = Join-Path $TEMP_DIR "jitterbugpair.zip"

try {
    Write-Host ">>> Downloading jitterbugpair (SideStore pairing)..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $jitterbugUrl -OutFile $jitterbugZip -UseBasicParsing
    Expand-Archive -Path $jitterbugZip -DestinationPath $BIN_DIR -Force
    Write-Host "[OK] jitterbugpair installed to $BIN_DIR" -ForegroundColor Green
} catch {
    Write-Host "[!] Could not auto-download jitterbugpair: $_" -ForegroundColor Yellow
    Write-Host "    You can manually place jitterbugpair.exe into $BIN_DIR" -ForegroundColor Yellow
}

if (Test-Path $TEMP_DIR) {
    Remove-Item -Path $TEMP_DIR -Recurse -Force
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Local tools check in $BIN_DIR:" -ForegroundColor Green
Get-ChildItem -Path $BIN_DIR -Filter "*.exe" | Select-Object Name
Write-Host "==========================================================" -ForegroundColor Green
