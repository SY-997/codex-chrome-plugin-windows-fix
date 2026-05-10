@echo off
setlocal

cd /d "%~dp0.."

echo Running Codex Chrome plugin verification...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0verify.ps1" %* 2>&1
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if "%EXIT_CODE%"=="0" (
  echo Verification completed successfully.
) else (
  echo Verification failed with exit code %EXIT_CODE%.
)
echo.

if /i not "%CODEX_NO_PAUSE%"=="1" pause
exit /b %EXIT_CODE%
