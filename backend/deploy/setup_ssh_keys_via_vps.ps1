# PowerShell script for SSH keys setup for Synology via VPS
# Usage: .\setup_ssh_keys_via_vps.ps1
# Use this if direct connection to Synology doesn't work

$ErrorActionPreference = "Stop"

# Colors
function Write-Success { Write-Host "OK: $args" -ForegroundColor Green }
function Write-Info { Write-Host "INFO: $args" -ForegroundColor Yellow }
function Write-Error-Custom { Write-Host "ERROR: $args" -ForegroundColor Red; exit 1 }
function Write-Section {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "$args" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}

# Variables
$VPS_IP = if ($env:VPS_IP) { $env:VPS_IP } else { "159.255.37.158" }
$VPS_USER = if ($env:VPS_USER) { $env:VPS_USER } else { "root" }
$SYNO_HOST = if ($env:SYNO_HOST_VPN) { $env:SYNO_HOST_VPN } else { "10.8.0.2" }
$SYNO_USER = if ($env:SYNO_USER) { $env:SYNO_USER } else { "admin" }
$LOCAL_KEY_NAME = "shortsai_synology"
$SSH_DIR = "$env:USERPROFILE\.ssh"
$LOCAL_KEY_PATH = "$SSH_DIR\$LOCAL_KEY_NAME"

Write-Section "SSH Keys Setup for Synology via VPS"

# 1. Create .ssh directory
Write-Info "Checking .ssh directory..."
if (-not (Test-Path $SSH_DIR)) {
    New-Item -ItemType Directory -Path $SSH_DIR -Force | Out-Null
}
Write-Success ".ssh directory ready"

# 2. Check existing key
Write-Info "Checking existing keys..."
$KEY_EXISTS = Test-Path $LOCAL_KEY_PATH

if ($KEY_EXISTS) {
    Write-Info "Key $LOCAL_KEY_NAME already exists"
    $response = Read-Host "Recreate key? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        Remove-Item "$LOCAL_KEY_PATH*" -Force -ErrorAction SilentlyContinue
        Write-Info "Old key removed"
        $KEY_EXISTS = $false
    } else {
        Write-Success "Using existing key"
    }
}

# 3. Create new key
if (-not $KEY_EXISTS) {
    Write-Info "Creating new SSH key: $LOCAL_KEY_NAME"
    
    $sshKeygen = Get-Command ssh-keygen -ErrorAction SilentlyContinue
    if (-not $sshKeygen) {
        Write-Error-Custom "ssh-keygen not found. Install Git for Windows or use WSL."
    }
    
    & ssh-keygen -t ed25519 -f $LOCAL_KEY_PATH -C "synology-access" -N '""' 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to create key"
    }
    
    Write-Success "SSH key created: $LOCAL_KEY_PATH"
}

# 4. Check if files exist
if (-not (Test-Path $LOCAL_KEY_PATH) -or -not (Test-Path "$LOCAL_KEY_PATH.pub")) {
    Write-Error-Custom "Key files not found"
}

Write-Info "Public key: $LOCAL_KEY_PATH.pub"
Write-Success "Keys ready"

# 5. Copy public key to Synology via VPS
Write-Section "Copying key to Synology via VPS"

Write-Info "Copying public key to Synology ($SYNO_USER@$SYNO_HOST) via VPS ($VPS_USER@$VPS_IP)"
Write-Info "You will need to enter VPS password, then Synology password"

# Read public key
$PUBKEY_CONTENT = Get-Content "$LOCAL_KEY_PATH.pub" -Raw

# Copy key to VPS first
Write-Info "Step 1: Copying public key to VPS..."
$randomId = Get-Random
$tempVpsFile = "/tmp/shortsai_pubkey_$randomId.pub"
$tempLocalFile = "$env:TEMP\shortsai_pubkey_$randomId.pub"
Set-Content -Path $tempLocalFile -Value $PUBKEY_CONTENT.Trim()

& scp $tempLocalFile "${VPS_USER}@${VPS_IP}:$tempVpsFile"
if ($LASTEXITCODE -ne 0) {
    Remove-Item $tempLocalFile -Force -ErrorAction SilentlyContinue
    Write-Error-Custom "Failed to copy key to VPS"
}

# Copy from VPS to Synology
Write-Info "Step 2: Copying public key from VPS to Synology..."
# Escape the public key content for SSH command
$PUBKEY_ESCAPED = $PUBKEY_CONTENT.Trim().Replace("'", "'\''")
$sshCmd = "scp $tempVpsFile ${SYNO_USER}@${SYNO_HOST}:~/.ssh/temp_pubkey.pub && ssh ${SYNO_USER}@${SYNO_HOST} 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat ~/.ssh/temp_pubkey.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm ~/.ssh/temp_pubkey.pub' && rm $tempVpsFile"

& ssh "${VPS_USER}@${VPS_IP}" $sshCmd
$copyResult = $LASTEXITCODE

# Cleanup
Remove-Item $tempLocalFile -Force -ErrorAction SilentlyContinue

if ($copyResult -ne 0) {
    Write-Error-Custom "Failed to copy key to Synology via VPS"
}

Write-Success "Public key copied to Synology via VPS"

# 6. Test connection
Write-Section "Testing connection"

Write-Info "Testing connection without password..."
$testCmd = 'echo "SSH key login OK"; whoami; pwd'
$result = & ssh "${VPS_USER}@${VPS_IP}" "ssh -o ConnectTimeout=5 -o BatchMode=yes ${SYNO_USER}@${SYNO_HOST} $testCmd" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "SSH key login works via VPS!"
    $result
} else {
    Write-Info "WARNING: Direct test failed, but key should be copied. Try manual connection."
}

# 7. Setup ~/.ssh/config
Write-Section "Setting up SSH config"

$SSH_CONFIG = "$SSH_DIR\config"
Write-Info "Updating $SSH_CONFIG..."

if (-not (Test-Path $SSH_CONFIG)) {
    New-Item -ItemType File -Path $SSH_CONFIG -Force | Out-Null
}

$configContent = Get-Content $SSH_CONFIG -Raw -ErrorAction SilentlyContinue
$needsUpdate = $true

if ($configContent -match "Host synology-shortsai") {
    Write-Info "Entry for synology-shortsai already exists in config"
    $response = Read-Host "Update? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        $needsUpdate = $false
        Write-Info "Skipping SSH config update"
    } else {
        $lines = Get-Content $SSH_CONFIG | Where-Object { $_ -notmatch "^Host synology-shortsai" -and $_ -notmatch "^\s+(HostName|User|IdentityFile|IdentitiesOnly|StrictHostKeyChecking|ProxyJump)" }
        $lines | Set-Content $SSH_CONFIG
    }
}

if ($needsUpdate) {
    # Add entry with ProxyJump for VPS
    $newConfig = @"

Host synology-shortsai
    HostName $SYNO_HOST
    User $SYNO_USER
    IdentityFile $LOCAL_KEY_PATH
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    ProxyJump $VPS_USER@$VPS_IP
"@
    Add-Content -Path $SSH_CONFIG -Value $newConfig
    
    Write-Success "SSH config updated with ProxyJump"
}

Write-Section "Done!"

Write-Success "SSH keys setup completed!"
Write-Host ""
Write-Info "Now you can connect to Synology via VPS:"
Write-Host "  ssh synology-shortsai" -ForegroundColor Green
Write-Host "  ssh $VPS_USER@$VPS_IP 'ssh $SYNO_USER@$SYNO_HOST'" -ForegroundColor Green
Write-Host ""
Write-Info "Next step: update deploy scripts to use the key"

