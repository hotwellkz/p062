# PowerShell скрипт для загрузки docker-compose.yml на сервер
# Использует метод с base64 кодированием

$filePath = "backend/docker-compose.yml"
$remotePath = "/volume1/docker/shortsai/backend/docker-compose.yml"
$sshHost = "admin@hotwell.synology.me"
$sshPort = 777

Write-Host "Читаю файл $filePath..." -ForegroundColor Yellow

if (-not (Test-Path $filePath)) {
    Write-Host "Ошибка: Файл $filePath не найден!" -ForegroundColor Red
    exit 1
}

$content = Get-Content $filePath -Raw -Encoding UTF8

# Кодируем в base64 для безопасной передачи
$base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))

Write-Host "Загружаю файл на сервер..." -ForegroundColor Yellow
Write-Host "Выполните команду вручную:" -ForegroundColor Cyan
Write-Host ""
Write-Host "ssh -p $sshPort $sshHost 'cd /volume1/docker/shortsai/backend && echo ""$base64"" | base64 -d > docker-compose.yml'" -ForegroundColor White
Write-Host ""
Write-Host "Или используйте метод из UPLOAD_DOCKER_COMPOSE.md" -ForegroundColor Gray





