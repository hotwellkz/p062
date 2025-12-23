# Восстановление проекта prompt-6a4fd в Cloud Run
# Usage: .\restore-cloud-run.ps1

$ErrorActionPreference = "Stop"

$PROJECT_ID = "prompt-6a4fd"
$REGION = "us-central1"

Write-Host "============================================" -ForegroundColor Green
Write-Host "Восстановление проекта $PROJECT_ID в Cloud Run" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

# Проверка gcloud CLI
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Ошибка: gcloud CLI не установлен" -ForegroundColor Red
    Write-Host "Установите: https://cloud.google.com/sdk/docs/install"
    exit 1
}

# Установка проекта
Write-Host "📦 Устанавливаю проект: $PROJECT_ID" -ForegroundColor Yellow
gcloud config set project $PROJECT_ID

# Проверка биллинга
Write-Host "💳 Проверяю биллинг..." -ForegroundColor Yellow
$BILLING_ACCOUNT = gcloud billing projects describe $PROJECT_ID --format="value(billingAccountName)" 2>$null

if ([string]::IsNullOrEmpty($BILLING_ACCOUNT)) {
    Write-Host "❌ Биллинг не привязан!" -ForegroundColor Red
    Write-Host "Доступные billing accounts:" -ForegroundColor Yellow
    gcloud billing accounts list --format="table(name,displayName)"
    Write-Host ""
    Write-Host "Привяжите биллинг командой:" -ForegroundColor Yellow
    Write-Host "gcloud billing projects link $PROJECT_ID --billing-account=BILLING_ACCOUNT_ID"
    Write-Host ""
    $BILLING_ID = Read-Host "Введите BILLING_ACCOUNT_ID (или нажмите Enter для пропуска)"
    if ($BILLING_ID) {
        gcloud billing projects link $PROJECT_ID --billing-account=$BILLING_ID
        Write-Host "✅ Биллинг привязан" -ForegroundColor Green
    } else {
        Write-Host "❌ Биллинг не привязан. Продолжение невозможно." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ Биллинг привязан: $BILLING_ACCOUNT" -ForegroundColor Green
}

# Включение API
Write-Host "🔧 Включаю необходимые API..." -ForegroundColor Yellow
gcloud services enable `
  run.googleapis.com `
  artifactregistry.googleapis.com `
  cloudbuild.googleapis.com `
  cloudscheduler.googleapis.com `
  secretmanager.googleapis.com `
  storage.googleapis.com `
  firestore.googleapis.com `
  --project=$PROJECT_ID

Write-Host "✅ API включены" -ForegroundColor Green

# Проверка Firestore
Write-Host "🔥 Проверяю Firestore..." -ForegroundColor Yellow
$FIRESTORE_DB = gcloud firestore databases list --project=$PROJECT_ID --format="value(name)" 2>$null | Select-Object -First 1

if ([string]::IsNullOrEmpty($FIRESTORE_DB)) {
    Write-Host "⚠️  Firestore база данных не найдена. Создаю..." -ForegroundColor Yellow
    gcloud firestore databases create `
      --location=$REGION `
      --type=firestore-native `
      --project=$PROJECT_ID 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Firestore база данных создана" -ForegroundColor Green
    } else {
        Write-Host "⚠️  База данных уже существует или ошибка создания" -ForegroundColor Yellow
    }
} else {
    Write-Host "✅ Firestore база данных найдена" -ForegroundColor Green
}

# Создание секретов из .env файла
Write-Host "🔐 Настраиваю секреты..." -ForegroundColor Yellow

if (-not (Test-Path ".env")) {
    Write-Host "❌ Файл .env не найден!" -ForegroundColor Red
    Write-Host "Создайте .env файл на основе env.example"
    exit 1
}

# Функция для создания/обновления секрета
function Create-OrUpdate-Secret {
    param(
        [string]$SecretName,
        [string]$SecretValue
    )
    
    $exists = gcloud secrets describe $SecretName --project=$PROJECT_ID 2>$null
    if ($LASTEXITCODE -eq 0) {
        $SecretValue | gcloud secrets versions add $SecretName `
          --data-file=- `
          --project=$PROJECT_ID
        Write-Host "  ✅ Обновлен секрет: $SecretName" -ForegroundColor Green
    } else {
        $SecretValue | gcloud secrets create $SecretName `
          --data-file=- `
          --project=$PROJECT_ID
        Write-Host "  ✅ Создан секрет: $SecretName" -ForegroundColor Green
    }
}

# Читаем .env и создаем секреты
$envContent = Get-Content ".env" -Raw
$lines = $envContent -split "`n"

foreach ($line in $lines) {
    if ($line -match "^#") { continue }
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    
    if ($line -match "^([^=]+)=(.*)$") {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        
        # Убираем кавычки
        $value = $value -replace '^"(.*)"$', '$1'
        $value = $value -replace "^'(.*)'$", '$1'
        
        # Создаем секреты только для важных переменных
        switch ($key) {
            { $_ -in @("TELEGRAM_API_ID", "TELEGRAM_API_HASH", "TELEGRAM_SESSION_SECRET", "TELEGRAM_SESSION_ENCRYPTED", "SYNX_CHAT_ID") } {
                Create-OrUpdate-Secret $key $value
            }
            { $_ -in @("JWT_SECRET", "CRON_SECRET") } {
                Create-OrUpdate-Secret $key $value
            }
            { $_ -in @("GOOGLE_DRIVE_CLIENT_EMAIL", "GOOGLE_DRIVE_PRIVATE_KEY", "GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET") } {
                Create-OrUpdate-Secret $key $value
            }
            "FIREBASE_SERVICE_ACCOUNT" {
                if ($value -match "^\{" -and $value -match "\}$") {
                    Create-OrUpdate-Secret $key $value
                }
            }
        }
    }
}

Write-Host "✅ Секреты настроены" -ForegroundColor Green

# Запуск деплоя
Write-Host "🚀 Запускаю деплой..." -ForegroundColor Yellow
Push-Location $PSScriptRoot
bash deploy/deploy_cloud_run.sh
Pop-Location

Write-Host "============================================" -ForegroundColor Green
Write-Host "Восстановление завершено!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green





