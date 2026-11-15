@echo off
rem [Sprint 71 N2] Double-click: builds the Android app from main and puts it on our server (ship_apk.sh says what it
rem does). Needs Git for Windows (its sh, ssh and scp), Flutter, the server's key and the four GLM_ signing variables.
set "SH=%ProgramFiles%\Git\bin\sh.exe"
if not exist "%SH%" (
  echo Git for Windows was not found: install it from https://git-scm.com, then run this again.
  pause
  exit /b 1
)
"%SH%" "%~dp0ship_apk.sh" %*
echo.
pause
