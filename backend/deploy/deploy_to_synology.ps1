# PowerShell скрипт для деплоя на Synology
# Использование: .\deploy_to_synology.ps1

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

# Определяем директорию backend
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$BACKEND_DIR = Split-Path -Parent $SCRIPT_DIR
Set-Location $BACKEND_DIR

Write-Section "Deploy ShortsAI Backend to Synology"

# Определяем SSH команду
$SSH_CMD = "ssh"
$SCP_CMD = "scp"
if (Test-Path $SYNO_SSH_KEY) {
    $SSH_CMD = "ssh -i `"$SYNO_SSH_KEY`""
    $SCP_CMD = "scp -i `"$SYNO_SSH_KEY`""
    Write-Info "Using SSH key: $SYNO_SSH_KEY"
}

# Проверка SSH
Write-Info "Checking SSH connection..."
$testResult = & cmd /c "$SSH_CMD -o ConnectTimeout=5 -o BatchMode=yes $SYNO_USER@$SYNO_HOST echo 'SSH OK'" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "SSH connection works without password"
} else {
    Write-Info "SSH connection will require password"
}

# Проверка/создание директории
Write-Info "Checking directory on Synology: $SYNO_BACKEND_DIR"
& cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"mkdir -p $SYNO_BACKEND_DIR && ls -la $SYNO_BACKEND_DIR`"" | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to create/check directory"
}
Write-Success "Directory ready"

# Копирование файлов
Write-Section "Copying files to Synology"

# Создаём архив
Write-Info "Creating archive..."
$TEMP_TAR = "$env:TEMP\shortsai_backend_$(Get-Random).tar.gz"

# Используем tar через WSL или Git Bash если доступен
$tarCmd = $null
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    $tarCmd = "wsl tar"
} elseif (Get-Command bash -ErrorAction SilentlyContinue) {
    $tarCmd = "bash -c 'tar'"
} else {
    Write-Error-Custom "tar not found. Install Git for Windows or WSL."
}

# Создаём список исключений
$excludes = @(
    ".git",
    "node_modules",
    "tmp",
    "storage\videos",
    ".env",
    ".env.local",
    ".env.production",
    "dist",
    "*.log"
)

# Создаём архив через tar
$excludeArgs = $excludes | ForEach-Object { "--exclude=$_" }
$tarArgs = "-czf", $TEMP_TAR, $excludeArgs, "."

Write-Info "Creating archive with tar..."
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    & wsl tar -czf "/tmp/backend.tar.gz" --exclude=".git" --exclude="node_modules" --exclude="tmp" --exclude="storage/videos" --exclude=".env" --exclude=".env.local" --exclude=".env.production" --exclude="dist" --exclude="*.log" -C $BACKEND_DIR .
    $TEMP_TAR = "/tmp/backend.tar.gz"
    $useWSL = $true
} else {
    # Используем 7zip или другой архиватор
    Write-Info "Using alternative method..."
    # Создаём временную директорию для копирования
    $TEMP_DIR = "$env:TEMP\shortsai_backend_$(Get-Random)"
    New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
    
    # Копируем файлы (исключая ненужные)
    Get-ChildItem -Path $BACKEND_DIR -Recurse | Where-Object {
        $relPath = $_.FullName.Substring($BACKEND_DIR.Length + 1)
        $exclude = $false
        foreach ($excl in $excludes) {
            if ($relPath -like "*$excl*") {
                $exclude = $true
                break
            }
        }
        -not $exclude
    } | Copy-Item -Destination {
        $destPath = $_.FullName.Replace($BACKEND_DIR, $TEMP_DIR)
        $destDir = Split-Path $destPath -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        $destPath
    }
    
    # Создаём архив через Compress-Archive
    Compress-Archive -Path "$TEMP_DIR\*" -DestinationPath "$TEMP_TAR" -Force
    Remove-Item -Path $TEMP_DIR -Recurse -Force
}

Write-Info "Copying archive to Synology..."
& cmd /c "$SCP_CMD `"$TEMP_TAR`" $SYNO_USER@$SYNO_HOST`:/tmp/shortsai_backend.tar.gz"
if ($LASTEXITCODE -ne 0) {
    Remove-Item $TEMP_TAR -Force -ErrorAction SilentlyContinue
    Write-Error-Custom "Failed to copy archive"
}

Write-Info "Extracting archive on Synology..."
& cmd /c "$SSH_CMD $SYNO_USER@$SYNO_HOST `"cd $SYNO_BACKEND_DIR && tar -xzf /tmp/shortsai_backend.tar.gz && rm /tmp/shortsai_backend.tar.gz`""
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to extract archive"
}

if (-not $useWSL) {
    Remove-Item $TEMP_TAR -Force -ErrorAction SilentlyContinue
}

Write-Success "Files copied to Synology"

Write-Section "Deploy finished"

Write-Success "Code updated on Synology: $SYNO_BACKEND_DIR"
Write-Host ""
Write-Info "Next steps:"
Write-Host "  1. Connect to Synology: ssh $SYNO_USER@$SYNO_HOST" -ForegroundColor Green
Write-Host "  2. Go to directory: cd $SYNO_BACKEND_DIR" -ForegroundColor Green
Write-Host "  3. Install dependencies: npm install" -ForegroundColor Green
Write-Host "  4. Build project: npm run build" -ForegroundColor Green
Write-Host "  5. Configure .env file" -ForegroundColor Green
Write-Host "  6. Start with PM2: pm2 start dist/index.js --name shortsai-backend" -ForegroundColor Green
Write-Host ""




