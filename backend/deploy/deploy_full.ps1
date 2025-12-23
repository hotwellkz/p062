# PowerShell script for full deployment to Synology
# Usage: .\deploy_full.ps1
# Password will be requested interactively

$ErrorActionPreference = "Continue"

# Colors
function Write-Success { Write-Host "OK: $args" -ForegroundColor Green }
function Write-Info { Write-Host "INFO: $args" -ForegroundColor Yellow }
function Write-Error-Custom { Write-Host "ERROR: $args" -ForegroundColor Red }
function Write-Section {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "$args" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}

# Variables
$SYNO_HOST = "192.168.100.222"
$SYNO_USER = "admin"
$SYNO_BACKEND_DIR = "/volume1/Backends/shortsai-backend"

# Get directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$BACKEND_DIR = Split-Path -Parent $SCRIPT_DIR
Set-Location $BACKEND_DIR

Write-Section "Full Deploy ShortsAI Backend to Synology"

# Step 1: Copy code
Write-Section "Step 1: Copy code to Synology"

Write-Info "Connecting to Synology: ${SYNO_USER}@${SYNO_HOST}"
Write-Info "Directory on Synology: $SYNO_BACKEND_DIR"
Write-Info "Password will be requested for SSH"
Write-Host ""

# Check/create directory
Write-Info "Checking directory on Synology..."
$mkdirCmd = "mkdir -p $SYNO_BACKEND_DIR; ls -la $SYNO_BACKEND_DIR"
$result = & ssh "${SYNO_USER}@${SYNO_HOST}" $mkdirCmd 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to create/check directory"
    Write-Host "Output: $result"
    exit 1
}
Write-Success "Directory ready"

# Copy files
Write-Info "Copying files to Synology..."

if (Get-Command rsync -ErrorAction SilentlyContinue) {
    Write-Info "Using rsync..."
    & rsync -avz --delete `
        --exclude=".git" `
        --exclude="node_modules" `
        --exclude="tmp" `
        --exclude="storage/videos" `
        --exclude=".env" `
        --exclude=".env.local" `
        --exclude=".env.production" `
        --exclude="dist" `
        --exclude="*.log" `
        --exclude=".DS_Store" `
        "./" "${SYNO_USER}@${SYNO_HOST}:${SYNO_BACKEND_DIR}/"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to copy files via rsync"
        exit 1
    }
    Write-Success "Files copied via rsync"
} else {
    Write-Info "rsync not found, using scp..."
    Write-Info "Creating archive..."
    
    # Use WSL tar if available
    if (Get-Command wsl -ErrorAction SilentlyContinue) {
        Write-Info "Using WSL tar..."
        & wsl bash -c "cd '$($BACKEND_DIR -replace '\\', '/')' && tar -czf /tmp/backend.tar.gz --exclude='.git' --exclude='node_modules' --exclude='tmp' --exclude='storage/videos' --exclude='.env' --exclude='.env.local' --exclude='.env.production' --exclude='dist' --exclude='*.log' --exclude='.DS_Store' ."
        
        Write-Info "Copying archive to Synology..."
        & wsl scp "/tmp/backend.tar.gz" "${SYNO_USER}@${SYNO_HOST}:/tmp/shortsai_backend.tar.gz"
        
        Write-Info "Extracting archive on Synology..."
        $extractCmd = "cd $SYNO_BACKEND_DIR; tar -xzf /tmp/shortsai_backend.tar.gz; rm /tmp/shortsai_backend.tar.gz"
        & ssh "${SYNO_USER}@${SYNO_HOST}" $extractCmd
    } else {
        Write-Error-Custom "rsync and WSL not found. Please install Git for Windows or WSL."
        exit 1
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to copy files"
        exit 1
    }
    Write-Success "Files copied"
}

# Step 2: Install and run on Synology
Write-Section "Step 2: Install and run on Synology"

Write-Info "Executing installation on Synology..."
Write-Info "Password will be requested for SSH (if not already entered)"
Write-Host ""

# Build command string
$setupCmd = "cd $SYNO_BACKEND_DIR; "
$setupCmd += "if [ ! -f dist/index.js ]; then "
$setupCmd += "echo 'Installing dependencies...'; "
$setupCmd += "npm install pm2 --save-dev; "
$setupCmd += "npm install; "
$setupCmd += "echo 'Building project...'; "
$setupCmd += "npm run build; "
$setupCmd += "fi; "
$setupCmd += "echo 'Stopping old process...'; "
$setupCmd += "node_modules/.bin/pm2 stop shortsai-backend 2>/dev/null; true; "
$setupCmd += "node_modules/.bin/pm2 delete shortsai-backend 2>/dev/null; true; "
$setupCmd += "echo 'Starting backend...'; "
$setupCmd += "node_modules/.bin/pm2 start dist/index.js --name shortsai-backend; "
$setupCmd += "node_modules/.bin/pm2 save; "
$setupCmd += "echo 'PM2 Status:'; "
$setupCmd += "node_modules/.bin/pm2 status"

Write-Info "Executing commands on Synology..."
& ssh "${SYNO_USER}@${SYNO_HOST}" $setupCmd

if ($LASTEXITCODE -eq 0) {
    Write-Success "Backend successfully installed and started!"
} else {
    Write-Error-Custom "Error during installation on Synology"
    Write-Info "Check logs manually: ssh ${SYNO_USER}@${SYNO_HOST} 'cd $SYNO_BACKEND_DIR && node_modules/.bin/pm2 logs shortsai-backend'"
}

Write-Section "Deploy completed!"

Write-Success "Check backend status:"
Write-Host "  ssh ${SYNO_USER}@${SYNO_HOST} 'curl http://localhost:8080/health'" -ForegroundColor Green
Write-Host ""
