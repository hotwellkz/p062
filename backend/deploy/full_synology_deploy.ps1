# PowerShell скрипт для полного деплоя на Synology
# Использование: .\full_synology_deploy.ps1

$ErrorActionPreference = "Stop"

# Цвета
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

# Переменные
$SYNO_HOST = if ($env:SYNO_HOST) { $env:SYNO_HOST } else { "192.168.100.222" }
$SYNO_USER = if ($env:SYNO_USER) { $env:SYNO_USER } else { "admin" }
$SYNO_BACKEND_DIR = if ($env:SYNO_BACKEND_DIR) { $env:SYNO_BACKEND_DIR } else { "/volume1/Hotwell/Backends/shortsai-backend" }
$SYNO_SSH_KEY = if ($env:SYNO_SSH_KEY) { $env:SYNO_SSH_KEY } else { "$env:USERPROFILE\.ssh\shortsai_synology" }

# Определяем директорию
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$BACKEND_DIR = Split-Path -Parent $SCRIPT_DIR
Set-Location $BACKEND_DIR

Write-Section "Full Deploy ShortsAI Backend to Synology"

# Определяем SSH команду
$SSH_CMD = "ssh"
if (Test-Path $SYNO_SSH_KEY) {
    $SSH_CMD = "ssh -i `"$SYNO_SSH_KEY`""
    Write-Info "Using SSH key: $SYNO_SSH_KEY"
    # Проверяем ключ
    $testResult = & cmd /c "$SSH_CMD -o ConnectTimeout=5 -o BatchMode=yes $SYNO_USER@$SYNO_HOST echo 'SSH key works'" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "SSH key works without password"
    } else {
        Write-Info "SSH key doesn't work, will use password"
        $SSH_CMD = "ssh"
    }
} else {
    Write-Info "SSH key not found, will use password"
}

# Шаг 1: Деплой кода
Write-Section "Step 1: Deploy code to Synology"
& "$SCRIPT_DIR\deploy_to_synology.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Code deployment failed"
}

# Шаг 2: Проверка Node.js и PM2
Write-Section "Step 2: Check Node.js and PM2"
Write-Info "Checking Node.js..."
$nodeCheckCmd = "node -v 2>/dev/null || echo NO_NODE"
$nodeVersion = & cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"$nodeCheckCmd`""
if ($nodeVersion -eq "NO_NODE") {
    Write-Error-Custom "Node.js is not installed on Synology. Install via Package Center."
} else {
    Write-Success "Node.js: $nodeVersion"
}

Write-Info "Checking npm..."
$npmCheckCmd = 'npm -v 2>/dev/null || echo NO_NPM'
$npmVersion = & cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"$npmCheckCmd`""
if ($npmVersion -eq "NO_NPM") {
    Write-Error-Custom "npm is not installed on Synology."
} else {
    Write-Success "npm: $npmVersion"
}

Write-Info "Checking pm2..."
$pm2CheckCmd = 'pm2 -v 2>/dev/null || echo NO_PM2'
$pm2Version = & cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"$pm2CheckCmd`""
if ($pm2Version -eq "NO_PM2") {
    Write-Info "pm2 is not installed, installing..."
    $pm2InstallCmd = "cd $SYNO_BACKEND_DIR; npm install -g pm2 || npm install pm2"
    & cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"$pm2InstallCmd`"" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to install pm2"
    }
    Write-Success "pm2 installed"
} else {
    Write-Success "pm2: $pm2Version"
}

# Шаг 3: Настройка .env
Write-Section "Step 3: Setup .env"
Write-Info "Checking .env on Synology..."
$envCheckCmd = "test -f $SYNO_BACKEND_DIR/.env && echo YES || echo NO"
$envExists = & cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"$envCheckCmd`""
if ($envExists -eq "NO") {
    Write-Info ".env not found, creating from env.example..."
    $cpCmd = "cd $SYNO_BACKEND_DIR; cp env.example .env"
    & cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"$cpCmd`"" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to create .env"
    }
    Write-Info "WARNING: Configure .env on Synology manually!"
    Write-Info "  Execute: ssh $SYNO_USER@$SYNO_HOST"
    Write-Info "  Then: nano $SYNO_BACKEND_DIR/.env"
} else {
    Write-Success ".env already exists"
}

# Шаг 4: Установка зависимостей и сборка
Write-Section "Step 4: Install dependencies and build"
Write-Info "Installing dependencies..."
$installCmd = "cd $SYNO_BACKEND_DIR; rm -rf node_modules; npm install"
& cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"$installCmd`"" | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to install dependencies"
}
Write-Success "Dependencies installed"

Write-Info "Building project..."
$buildCmd = "cd $SYNO_BACKEND_DIR; npm run build"
& cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"$buildCmd`"" | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to build project"
}
Write-Success "Project built"

# Шаг 5: Запуск через PM2
Write-Section "Step 5: Start with PM2"
Write-Info "Stopping old process (if exists)..."
$stopCmd = "cd $SYNO_BACKEND_DIR; pm2 stop shortsai-backend 2>/dev/null; true"
& cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"$stopCmd`"" | Out-Null
$deleteCmd = "cd $SYNO_BACKEND_DIR; pm2 delete shortsai-backend 2>/dev/null; true"
& cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"$deleteCmd`"" | Out-Null

Write-Info "Starting backend with PM2..."
$startCmd = "cd $SYNO_BACKEND_DIR; pm2 start dist/index.js --name shortsai-backend"
& cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"$startCmd`"" | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to start backend"
}

Write-Info "Saving PM2 configuration..."
$saveCmd = "cd $SYNO_BACKEND_DIR; pm2 save"
& cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"$saveCmd`"" | Out-Null

Write-Info "Checking status..."
& cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"pm2 status`""
Write-Success "Backend started with PM2"

# Шаг 6: Проверка работы
Write-Section "Step 6: Check backend"
Write-Info "Determining port from .env..."
$port = & cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"grep -E '^PORT=' $SYNO_BACKEND_DIR/.env | cut -d'=' -f2 | tr -d '\"`"" 2>&1
if ([string]::IsNullOrWhiteSpace($port)) {
    $port = "8080"
}
Write-Info "Backend port: $port"

Write-Info "Checking health endpoint..."
$healthCmd = 'curl -s http://localhost:' + $port + '/health || curl -s http://localhost:' + $port + '/ || echo ERROR'
$healthResponse = & cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"$healthCmd`"" 2>&1
if ($healthResponse -ne "ERROR" -and -not [string]::IsNullOrWhiteSpace($healthResponse)) {
    Write-Success "Backend is responding!"
    Write-Host "Response: $healthResponse"
} else {
    Write-Info "WARNING: Backend is not responding to health endpoint"
    Write-Info "Check logs: pm2 logs shortsai-backend"
}

Write-Section "Deploy completed!"

Write-Success "Backend successfully deployed to Synology!"
Write-Host ""
Write-Info "Useful commands:"
Write-Host "  Update code: bash deploy/deploy_to_synology.sh" -ForegroundColor Green
$restartLine = '  Restart backend: ssh ' + $SYNO_USER + '@' + $SYNO_HOST + ' pm2 restart shortsai-backend'
Write-Host $restartLine -ForegroundColor Green
$logsLine = '  View logs: ssh ' + $SYNO_USER + '@' + $SYNO_HOST + ' pm2 logs shortsai-backend'
Write-Host $logsLine -ForegroundColor Green
$statusLine = '  Status: ssh ' + $SYNO_USER + '@' + $SYNO_HOST + ' pm2 status'
Write-Host $statusLine -ForegroundColor Green
$healthPort = $port
$healthCheckLine = '  Health check: ssh ' + $SYNO_USER + '@' + $SYNO_HOST + ' curl http://localhost:' + $healthPort + '/health'
Write-Host $healthCheckLine -ForegroundColor Green
Write-Host ""

