@echo off
rem Double-click: the latest main from GitHub to our server (deploy.ps1 says what it does, step by step).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" %*
echo.
pause
