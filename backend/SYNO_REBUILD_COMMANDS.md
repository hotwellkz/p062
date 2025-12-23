# Команды для пересборки контейнера на Synology

Выполните эти команды в текущей SSH сессии на Synology:

```bash
# 1. Пересобрать контейнер (повторить, если была сетевая ошибка)
cd /volume1/docker/shortsai/backend
sudo /usr/local/bin/docker compose build --no-cache

# 2. Если сборка успешна, запустить контейнер
sudo /usr/local/bin/docker compose up -d

# 3. Проверить статус
sudo /usr/local/bin/docker compose ps

# 4. Проверить логи
sudo docker logs shorts-backend --tail 50

# 5. Проверить, что JWT_SECRET установлен
grep JWT_SECRET .env.production

# Если JWT_SECRET нет, добавить:
echo "JWT_SECRET=dev_jwt_secret_129384712983471" >> .env.production
sudo /usr/local/bin/docker compose restart
```

## После успешной пересборки - тестирование

С вашего ПК (PowerShell):

```powershell
# Генерация нового JWT токена
cd backend
$env:JWT_SECRET='dev_jwt_secret_129384712983471'
$token = node -e "console.log(require('jsonwebtoken').sign({role:'admin'}, process.env.JWT_SECRET || 'dev_jwt_secret_129384712983471'))"
Write-Host "Токен: $token"

# Тест запроса
$body = '{\"channelId\":\"test\",\"url\":\"https://getvideo.syntxai.net/IDF8F06K0bmB\"}'
curl.exe -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer $token" `
  -d $body
```

**Ожидаемый результат:**
- HTTP 200/202 (если параметры валидны)
- ИЛИ HTTP 400/500 с описанием ошибки
- **НЕ 401 INVALID_TOKEN!**

## Проверка логов на Synology

```bash
sudo docker logs shorts-backend --tail 100 | grep -i "authRequired\|jwt\|firebase"
```

Должны быть логи:
- `authRequired: using local JWT authentication`
- `authRequired: local JWT token verified successfully`

