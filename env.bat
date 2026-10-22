@echo off
REM Local Environment Session for Flutter iOS Development
REM This script only alters the current terminal session, NOT global system PATH.

set "IOS_ROOT=%~dp0"
if "%IOS_ROOT:~-1%"=="\" set "IOS_ROOT=%IOS_ROOT:~0,-1%"

set "FLUTTER_ROOT=%IOS_ROOT%\flutter"
set "TOOLS_BIN=%IOS_ROOT%\tools\bin"

echo ========================================================
echo  Local Flutter iOS Workspace (D:\source\IOS)
echo ========================================================

if exist "%FLUTTER_ROOT%\bin" (
    set "PATH=%FLUTTER_ROOT%\bin;%TOOLS_BIN%;%PATH%"
    echo [OK] Local Flutter detected: %FLUTTER_ROOT%
) else (
    echo [!] Local Flutter not found in %FLUTTER_ROOT%
    echo     Run 'powershell -ExecutionPolicy Bypass -File tools\install-local-flutter.ps1' to download it locally.
)

if exist "%TOOLS_BIN%" (
    set "PATH=%TOOLS_BIN%;%PATH%"
    echo [OK] Local Tools detected: %TOOLS_BIN%
)

echo [OK] Session configured. You can now run 'flutter' commands here.
echo ========================================================
cmd /k
