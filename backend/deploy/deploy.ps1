# PowerShell script to run deployment from Windows
# Usage: .\deploy.ps1

Write-Host "Starting ShortsAI Studio autodeploy" -ForegroundColor Cyan
Write-Host ""

# Check if bash is available
if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: bash not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install one of the following:" -ForegroundColor Yellow
    Write-Host "  1. Git for Windows (includes Git Bash)" -ForegroundColor Yellow
    Write-Host "  2. WSL (Windows Subsystem for Linux)" -ForegroundColor Yellow
    Write-Host "  3. Use manual deployment (see WINDOWS_DEPLOY.md)" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Change to script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "Directory: $scriptDir" -ForegroundColor Green
Write-Host ""

# Run bash script
Write-Host "Running full_deploy.sh via bash..." -ForegroundColor Cyan
Write-Host ""

bash full_deploy.sh

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Deployment completed successfully!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Deployment failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check logs above or use manual deployment (see WINDOWS_DEPLOY.md)" -ForegroundColor Yellow
    exit $LASTEXITCODE
}
