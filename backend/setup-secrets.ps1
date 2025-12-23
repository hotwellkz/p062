# Настройка секретов в Secret Manager для Cloud Run
# Usage: .\setup-secrets.ps1

$ErrorActionPreference = "Stop"

$PROJECT_ID = "prompt-6a4fd"

Write-Host "============================================" -ForegroundColor Green
Write-Host "Настройка секретов в Secret Manager" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

# Функция для создания/обновления секрета
function Create-OrUpdate-Secret {
    param(
        [string]$SecretName,
        [string]$SecretValue
    )
    
    if ([string]::IsNullOrEmpty($SecretValue)) {
        Write-Host "  ⚠️  Пропущен секрет: $SecretName (значение пустое)" -ForegroundColor Yellow
        return
    }
    
    $exists = gcloud secrets describe $SecretName --project=$PROJECT_ID 2>$null
    if ($LASTEXITCODE -eq 0) {
        $SecretValue | gcloud secrets versions add $SecretName `
          --data-file=- `
          --project=$PROJECT_ID 2>$null
        Write-Host "  ✅ Обновлен секрет: $SecretName" -ForegroundColor Green
    } else {
        $SecretValue | gcloud secrets create $SecretName `
          --data-file=- `
          --project=$PROJECT_ID 2>$null
        Write-Host "  ✅ Создан секрет: $SecretName" -ForegroundColor Green
    }
}

# Читаем переменные из .env файла
if (-not (Test-Path ".env")) {
    Write-Host "❌ Файл .env не найден!" -ForegroundColor Red
    Write-Host "Создайте .env файл на основе env.example"
    exit 1
}

Write-Host "📝 Читаю переменные из .env..." -ForegroundColor Yellow

# Читаем .env файл
$envContent = Get-Content ".env" -Raw
$lines = $envContent -split "`n"

$secrets = @{}

foreach ($line in $lines) {
    if ($line -match "^#") { continue }
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    
    if ($line -match "^([^=]+)=(.*)$") {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        
        # Убираем кавычки
        $value = $value -replace '^"(.*)"$', '$1'
        $value = $value -replace "^'(.*)'$", '$1'
        
        # Обработка многострочных значений (FIREBASE_PRIVATE_KEY)
        if ($key -eq "FIREBASE_PRIVATE_KEY" -and $value -match "-----BEGIN") {
            # Читаем до следующей переменной или конца файла
            $fullValue = $value
            $lineIndex = $lines.IndexOf($line)
            for ($i = $lineIndex + 1; $i -lt $lines.Length; $i++) {
                if ($lines[$i] -match "^[A-Z_]+=") {
                    break
                }
                if (-not [string]::IsNullOrWhiteSpace($lines[$i])) {
                    $fullValue += "`n" + $lines[$i].Trim()
                }
            }
            $value = $fullValue
        }
        
        # Сохраняем только нужные секреты
        switch ($key) {
            { $_ -in @("TELEGRAM_API_ID", "TELEGRAM_API_HASH", "TELEGRAM_SESSION_SECRET", "TELEGRAM_SESSION_ENCRYPTED", "SYNX_CHAT_ID") } {
                $secrets[$key] = $value
            }
            { $_ -in @("JWT_SECRET", "CRON_SECRET") } {
                $secrets[$key] = $value
            }
            { $_ -in @("GOOGLE_DRIVE_CLIENT_EMAIL", "GOOGLE_DRIVE_PRIVATE_KEY", "GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET") } {
                $secrets[$key] = $value
            }
            "FIREBASE_SERVICE_ACCOUNT" {
                if ($value -match "^\{" -and $value -match "\}$") {
                    $secrets[$key] = $value
                }
            }
        }
    }
}

# Создаем секреты
Write-Host "🔐 Создаю секреты..." -ForegroundColor Yellow

foreach ($secretName in $secrets.Keys) {
    Create-OrUpdate-Secret $secretName $secrets[$secretName]
}

Write-Host ""
Write-Host "✅ Секреты настроены" -ForegroundColor Green
Write-Host ""
Write-Host "Следующий шаг: запустите деплой" -ForegroundColor Yellow
Write-Host "bash deploy/deploy_cloud_run.sh" -ForegroundColor Cyan





