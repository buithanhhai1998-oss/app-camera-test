# Extracts iOS crash logs (.ips) from physical iPhone to D:\source\IOS\crash_logs
$IOS_ROOT = Split-Path -Parent $PSScriptRoot
$REPORT_EXE = Join-Path $IOS_ROOT "tools\bin\idevicecrashreport.exe"
$OUTPUT_DIR = Join-Path $IOS_ROOT "crash_logs"

if (-not (Test-Path $REPORT_EXE)) {
    Write-Host "[!] idevicecrashreport.exe not found at $REPORT_EXE" -ForegroundColor Yellow
    Write-Host "    Run 'powershell tools\install-local-tools.ps1' to fetch it locally." -ForegroundColor Yellow
    exit 1
}

New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null

Write-Host ">>> Extracting crash logs from connected iPhone..." -ForegroundColor Cyan
& $REPORT_EXE -e $OUTPUT_DIR

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " [OK] Crash reports saved to: $OUTPUT_DIR" -ForegroundColor Green
Get-ChildItem -Path $OUTPUT_DIR -Filter "*.ips" | Select-Object Name, Length, LastWriteTime
Write-Host " Open the .ips files in VS Code to inspect the crashed thread callstack." -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
