@echo off
setlocal
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0THC_Patch_AA_Slider.ps1"
if errorlevel 1 (
  echo.
  echo The Hero Chronicles launcher could not patch or start eqgame.exe.
  echo Read the message above, then close this window.
  pause
)
