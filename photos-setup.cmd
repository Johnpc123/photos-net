@echo off
REM Double-clickable launcher for Windows family members.
REM Just runs bin\photos-setup.ps1 with execution policy bypassed.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bin\photos-setup.ps1" %*
echo.
pause
