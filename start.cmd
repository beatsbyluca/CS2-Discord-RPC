@echo off
setlocal
cd /d "%~dp0"
if not exist "logs" mkdir "logs"
set "NODE_EXE=node"
if exist "%~dp0runtime\node.exe" set "NODE_EXE=%~dp0runtime\node.exe"
if "%NODE_EXE%"=="node" (
    where node >nul 2>nul
    if errorlevel 1 (
        echo Node.js is missing. Run Setup.cmd first.
        pause
        exit /b 1
    )
)
echo CS2 Discord RPC is running. Keep this window open while playing.
echo Logs: "%~dp0logs"
"%NODE_EXE%" "%~dp0src\main.js" >> "%~dp0logs\app.log" 2>> "%~dp0logs\error.log"
echo CS2 Discord RPC stopped. Check logs\error.log if it exited unexpectedly.
pause
