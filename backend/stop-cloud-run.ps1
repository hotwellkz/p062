# Остановка Cloud Run сервисов для работы только на Synology
# Usage: .\stop-cloud-run.ps1

$ErrorActionPreference = "Stop"

$PROJECT_ID = "prompt-6a4fd"
$REGION = "us-central1"

Write-Host "============================================" -ForegroundColor Yellow
Write-Host "Остановка Cloud Run сервисов" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow
Write-Host "Проект: $PROJECT_ID" -ForegroundColor Cyan
Write-Host "Регион: $REGION" -ForegroundColor Cyan
Write-Host ""

# Проверка статуса проекта
Write-Host "🔍 Проверяю статус проекта..." -ForegroundColor Yellow
$projectStatus = gcloud projects describe $PROJECT_ID --format="value(lifecycleState)" 2>$null

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($projectStatus)) {
    Write-Host "❌ Ошибка: Проект недоступен или приостановлен" -ForegroundColor Red
    Write-Host "Активируйте проект через Google Cloud Console" -ForegroundColor Yellow
    exit 1
}

if ($projectStatus -ne "ACTIVE") {
    Write-Host "⚠️  Проект не активен (статус: $projectStatus)" -ForegroundColor Yellow
    Write-Host "Активируйте проект через Google Cloud Console" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Проект активен" -ForegroundColor Green
Write-Host ""

# Список Cloud Run Services
Write-Host "📋 Поиск Cloud Run Services..." -ForegroundColor Yellow
$services = gcloud run services list --project=$PROJECT_ID --region=$REGION --format="value(metadata.name)" 2>$null

if ($LASTEXITCODE -eq 0 -and $services) {
    Write-Host "Найдено сервисов: $($services.Count)" -ForegroundColor Cyan
    
    foreach ($service in $services) {
        if ([string]::IsNullOrWhiteSpace($service)) { continue }
        
        Write-Host ""
        Write-Host "🛑 Останавливаю сервис: $service" -ForegroundColor Yellow
        
        # Удаляем сервис (это остановит его)
        gcloud run services delete $service `
          --region=$REGION `
          --project=$PROJECT_ID `
          --quiet 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Сервис $service удален" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Не удалось удалить $service (возможно, уже удален)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "ℹ️  Cloud Run Services не найдены" -ForegroundColor Cyan
}

Write-Host ""

# Список Cloud Run Jobs
Write-Host "📋 Поиск Cloud Run Jobs..." -ForegroundColor Yellow
$jobs = gcloud run jobs list --project=$PROJECT_ID --region=$REGION --format="value(metadata.name)" 2>$null

if ($LASTEXITCODE -eq 0 -and $jobs) {
    Write-Host "Найдено Jobs: $($jobs.Count)" -ForegroundColor Cyan
    
    foreach ($job in $jobs) {
        if ([string]::IsNullOrWhiteSpace($job)) { continue }
        
        Write-Host ""
        Write-Host "🛑 Удаляю Job: $job" -ForegroundColor Yellow
        
        gcloud run jobs delete $job `
          --region=$REGION `
          --project=$PROJECT_ID `
          --quiet 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Job $job удален" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Не удалось удалить $job (возможно, уже удален)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "ℹ️  Cloud Run Jobs не найдены" -ForegroundColor Cyan
}

Write-Host ""

# Остановка Cloud Scheduler Jobs
Write-Host "📋 Поиск Cloud Scheduler Jobs..." -ForegroundColor Yellow
$schedulers = gcloud scheduler jobs list --project=$PROJECT_ID --location=$REGION --format="value(name)" 2>$null

if ($LASTEXITCODE -eq 0 -and $schedulers) {
    Write-Host "Найдено Scheduler Jobs: $($schedulers.Count)" -ForegroundColor Cyan
    
    foreach ($scheduler in $schedulers) {
        if ([string]::IsNullOrWhiteSpace($scheduler)) { continue }
        
        # Извлекаем имя job из полного пути
        $jobName = $scheduler -replace ".*/", ""
        
        Write-Host ""
        Write-Host "🛑 Удаляю Scheduler Job: $jobName" -ForegroundColor Yellow
        
        gcloud scheduler jobs delete $jobName `
          --location=$REGION `
          --project=$PROJECT_ID `
          --quiet 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Scheduler Job $jobName удален" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Не удалось удалить $jobName (возможно, уже удален)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "ℹ️  Cloud Scheduler Jobs не найдены" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "✅ Остановка Cloud Run завершена" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Теперь работает только backend на Synology:" -ForegroundColor Cyan
Write-Host "  https://api.hotwell.synology.me" -ForegroundColor Yellow
Write-Host ""





