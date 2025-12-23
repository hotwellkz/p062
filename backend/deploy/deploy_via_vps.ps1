# PowerShell script to deploy to Synology via VPS (VPN tunnel)
# Use this if direct SSH to Synology doesn't work

$VPS_IP = "159.255.37.158"
$VPS_USER = "root"
$SYNO_IP = "10.8.0.2"
$SYNO_USER = "admin"
$LOCAL_SCRIPT = "backend\deploy\synology_deploy.sh"
$LOCAL_CONFIG = "backend\deploy\config.sh"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying to Synology via VPS (VPN)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Copy to VPS
Write-Host "[1/3] Copying files to VPS..." -ForegroundColor Yellow
scp $LOCAL_SCRIPT "${VPS_USER}@${VPS_IP}:/tmp/synology_deploy.sh"
scp $LOCAL_CONFIG "${VPS_USER}@${VPS_IP}:/tmp/config.sh"
Write-Host "Files copied to VPS" -ForegroundColor Green
Write-Host ""

# 2. Copy from VPS to Synology via VPN
Write-Host "[2/3] Copying files from VPS to Synology via VPN..." -ForegroundColor Yellow
ssh "${VPS_USER}@${VPS_IP}" "scp /tmp/synology_deploy.sh /tmp/config.sh ${SYNO_USER}@${SYNO_IP}:/tmp/"
Write-Host "Files copied to Synology" -ForegroundColor Green
Write-Host ""

# 3. Run deployment on Synology
Write-Host "[3/3] Running deployment on Synology..." -ForegroundColor Yellow
ssh "${VPS_USER}@${VPS_IP}" "ssh ${SYNO_USER}@${SYNO_IP} 'sed -i \"s/\\r`$//\" /tmp/synology_deploy.sh && chmod +x /tmp/*.sh && bash /tmp/synology_deploy.sh'"
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green





