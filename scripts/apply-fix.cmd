@echo off
setlocal

cd /d "%~dp0.."

echo Running Codex Chrome plugin fix...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0apply-fix.ps1" %* 2>&1
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if "%EXIT_CODE%"=="0" (
  echo Completed successfully.
) else (
  echo Failed with exit code %EXIT_CODE%.
)
echo.

if /i not "%CODEX_NO_PAUSE%"=="1" pause
exit /b %EXIT_CODE%
