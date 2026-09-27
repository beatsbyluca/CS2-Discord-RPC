@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup\wizard.ps1"
if errorlevel 1 (
    echo.
    echo Setup did not finish. Press any key to close this window.
    pause >nul
)
