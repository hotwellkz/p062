# Fully automated script to fix and deploy on VPS
# Usage: .\auto_fix_vps.ps1

$VPS_IP = "159.255.37.158"
$VPS_USER = "root"
$LOCAL_FILE = "backend\vps\synology-port-forward.sh"
$REMOTE_FILE = "/root/synology-port-forward.sh"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auto-fix and deploy on VPS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Copy file
Write-Host "[1/4] Copying file to VPS..." -ForegroundColor Yellow
scp $LOCAL_FILE "${VPS_USER}@${VPS_IP}:${REMOTE_FILE}"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to copy file" -ForegroundColor Red
    exit 1
}
Write-Host "File copied successfully" -ForegroundColor Green
Write-Host ""

# Step 2: Fix line endings
Write-Host "[2/4] Fixing line endings (CRLF -> LF)..." -ForegroundColor Yellow
ssh "${VPS_USER}@${VPS_IP}" "sed -i 's/\r`$//' $REMOTE_FILE"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to fix line endings" -ForegroundColor Red
    exit 1
}
Write-Host "Line endings fixed" -ForegroundColor Green
Write-Host ""

# Step 3: Set executable permissions
Write-Host "[3/4] Setting executable permissions..." -ForegroundColor Yellow
ssh "${VPS_USER}@${VPS_IP}" "chmod +x $REMOTE_FILE"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to set permissions" -ForegroundColor Red
    exit 1
}
Write-Host "Permissions set" -ForegroundColor Green
Write-Host ""

# Step 4: Run script
Write-Host "[4/4] Running synology-port-forward.sh..." -ForegroundColor Yellow
Write-Host ""
ssh "${VPS_USER}@${VPS_IP}" "bash $REMOTE_FILE"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SUCCESS! Script executed successfully" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "ERROR: Script execution failed" -ForegroundColor Red
    Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    exit $LASTEXITCODE
}





