# PowerShell script to copy file to VPS, fix line endings and run it
# Usage: .\fix_and_deploy_vps.ps1

$VPS_IP = "159.255.37.158"
$VPS_USER = "root"
$FILE = "backend\vps\synology-port-forward.sh"
$REMOTE_PATH = "/root/synology-port-forward.sh"

Write-Host "Copying file to VPS..." -ForegroundColor Cyan
scp $FILE "${VPS_USER}@${VPS_IP}:${REMOTE_PATH}"

Write-Host "Fixing line endings and running script on VPS..." -ForegroundColor Cyan
ssh "${VPS_USER}@${VPS_IP}" "sed -i 's/\r`$//' /root/synology-port-forward.sh && chmod +x /root/synology-port-forward.sh && bash /root/synology-port-forward.sh"

Write-Host "Done!" -ForegroundColor Green





