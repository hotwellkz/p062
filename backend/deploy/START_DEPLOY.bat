@echo off
REM Batch file to start deployment
REM This will use Git Bash if available, otherwise PowerShell

cd /d "%~dp0\.."

if exist "C:\Program Files\Git\bin\bash.exe" (
    echo Using Git Bash...
    "C:\Program Files\Git\bin\bash.exe" deploy/full_synology_deploy.sh
) else if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    echo Using Git Bash...
    "C:\Program Files (x86)\Git\bin\bash.exe" deploy/full_synology_deploy.sh
) else (
    echo Git Bash not found. Please install Git for Windows or run manually:
    echo   bash deploy/full_synology_deploy.sh
    pause
)
