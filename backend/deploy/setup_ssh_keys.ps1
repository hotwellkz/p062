# PowerShell script for SSH keys setup for Synology
# Usage: .\setup_ssh_keys.ps1

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
$SYNO_HOST = if ($env:SYNO_HOST) { $env:SYNO_HOST } else { "192.168.100.222" }
$SYNO_USER = if ($env:SYNO_USER) { $env:SYNO_USER } else { "admin" }
$LOCAL_KEY_NAME = "shortsai_synology"
$SSH_DIR = "$env:USERPROFILE\.ssh"
$LOCAL_KEY_PATH = "$SSH_DIR\$LOCAL_KEY_NAME"

Write-Section "SSH Keys Setup for Synology"

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
    
    # Check if ssh-keygen is available
    $sshKeygen = Get-Command ssh-keygen -ErrorAction SilentlyContinue
    if (-not $sshKeygen) {
        Write-Error-Custom "ssh-keygen not found. Install Git for Windows or use WSL."
    }
    
    # Create key
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

# 5. Copy public key to Synology
Write-Section "Copying key to Synology"

Write-Info "Copying public key to Synology ($SYNO_USER@$SYNO_HOST)"
Write-Info "You will need to enter password once"

# Read public key
$PUBKEY_CONTENT = Get-Content "$LOCAL_KEY_PATH.pub" -Raw

# Copy key to Synology
Write-Info "Copying key manually..."
Write-Info "IMPORTANT: If password doesn't work, try:"
Write-Info "  1. Use setup_ssh_keys_via_vps.ps1 (via VPS)"
Write-Info "  2. Or copy key manually (see SSH_SETUP_TROUBLESHOOTING.md)"
Write-Host ""

# Escape the public key content for SSH command
$PUBKEY_ESCAPED = $PUBKEY_CONTENT.Replace("'", "'\''")
$sshCmd = "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$PUBKEY_ESCAPED' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

Write-Info "Attempting to connect to $SYNO_USER@$SYNO_HOST..."
Write-Info "Enter password when prompted (you have 3 attempts)"

& ssh "$SYNO_USER@$SYNO_HOST" $sshCmd
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Failed to copy key. Possible reasons:" -ForegroundColor Red
    Write-Host "  1. Wrong password" -ForegroundColor Yellow
    Write-Host "  2. Synology not accessible directly" -ForegroundColor Yellow
    Write-Host "  3. SSH service issues on Synology" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Try alternative methods:" -ForegroundColor Cyan
    Write-Host "  - Use: .\setup_ssh_keys_via_vps.ps1 (via VPS)" -ForegroundColor Green
    Write-Host "  - Or: See SSH_SETUP_TROUBLESHOOTING.md for manual steps" -ForegroundColor Green
    Write-Host ""
    exit 1
}

Write-Success "Public key copied to Synology"

# 6. Test connection
Write-Section "Testing connection"

Write-Info "Testing connection without password..."
$testCmd = 'echo "SSH key login OK"; whoami; pwd'
$result = & ssh -i $LOCAL_KEY_PATH -o ConnectTimeout=5 -o BatchMode=yes "$SYNO_USER@$SYNO_HOST" $testCmd 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "SSH key login works!"
    $result
} else {
    Write-Error-Custom "SSH key login failed. Check Synology settings."
}

# 7. Setup ~/.ssh/config
Write-Section "Setting up SSH config"

$SSH_CONFIG = "$SSH_DIR\config"
Write-Info "Updating $SSH_CONFIG..."

# Create config if it doesn't exist
if (-not (Test-Path $SSH_CONFIG)) {
    New-Item -ItemType File -Path $SSH_CONFIG -Force | Out-Null
}

# Check if entry already exists
$configContent = Get-Content $SSH_CONFIG -Raw -ErrorAction SilentlyContinue
$needsUpdate = $true

if ($configContent -match "Host synology-shortsai") {
    Write-Info "Entry for synology-shortsai already exists in config"
    $response = Read-Host "Update? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        $needsUpdate = $false
        Write-Info "Skipping SSH config update"
    } else {
        # Remove old entry (simple way - recreate file without old entry)
        $lines = Get-Content $SSH_CONFIG | Where-Object { $_ -notmatch "^Host synology-shortsai" -and $_ -notmatch "^\s+(HostName|User|IdentityFile|IdentitiesOnly|StrictHostKeyChecking)" }
        $lines | Set-Content $SSH_CONFIG
    }
}

if ($needsUpdate) {
    # Add new entry
    $newConfig = @"

Host synology-shortsai
    HostName $SYNO_HOST
    User $SYNO_USER
    IdentityFile $LOCAL_KEY_PATH
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
"@
    Add-Content -Path $SSH_CONFIG -Value $newConfig
    
    Write-Success "SSH config updated"
    
    # Test through config
    Write-Info "Testing connection through SSH config..."
    $result = & ssh -o ConnectTimeout=5 -o BatchMode=yes synology-shortsai 'echo "config OK"; pwd' 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Connection through SSH config works!"
        $result
    } else {
        Write-Info "WARNING: Connection through config may require first manual connection"
    }
}

Write-Section "Done!"

Write-Success "SSH keys setup completed successfully!"
Write-Host ""
Write-Info "Now you can connect to Synology without password:"
Write-Host "  ssh synology-shortsai" -ForegroundColor Green
Write-Host "  ssh -i $LOCAL_KEY_PATH $SYNO_USER@$SYNO_HOST" -ForegroundColor Green
Write-Host ""
Write-Info "Next step: update deploy scripts to use the key"
