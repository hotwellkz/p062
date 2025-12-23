# Деплой Dual-Auth на Synology

## Шаги деплоя

### 1. Обновить код на Synology

```powershell
# С вашего ПК (Windows PowerShell)
cd backend\src\middleware
Get-Content auth.ts | ssh adminv@192.168.100.222 "cat > /volume1/docker/shortsai/backend/src/middleware/auth.ts"
```

### 2. Пересобрать контейнер на Synology

```bash
# На Synology (через SSH)
ssh adminv@192.168.100.222
cd /volume1/docker/shortsai/backend
sudo /usr/local/bin/docker compose down
sudo /usr/local/bin/docker compose build --no-cache
sudo /usr/local/bin/docker compose up -d
```

### 3. Проверить логи

```bash
# На Synology
sudo docker logs shorts-backend --tail 50 | grep -i "authRequired\|listening\|started"
```

### 4. Проверить, что JWT_SECRET установлен

```bash
# На Synology
cd /volume1/docker/shortsai/backend
grep JWT_SECRET .env.production
```

Если нет - добавить:
```bash
echo "JWT_SECRET=dev_jwt_secret_129384712983471" >> .env.production
sudo /usr/local/bin/docker compose restart
```

## Тестирование после деплоя

### Тест 1: Локальный JWT токен

```powershell
# С вашего ПК
$token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW4iLCJpYXQiOjE3NjYzMzQzMTJ9.S7c52s0EsTStP2vgb8WV-ZWCc1sQP4SuFLN-KMIeyKs"
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

### Тест 2: Проверка логов

```bash
# На Synology
sudo docker logs shorts-backend --tail 100 | grep -i "authRequired\|jwt\|firebase"
```

Должны быть логи:
- `authRequired: using local JWT authentication`
- `authRequired: local JWT token verified successfully`

## Откат (если что-то пошло не так)

```bash
# На Synology
cd /volume1/docker/shortsai/backend
git checkout HEAD -- src/middleware/auth.ts
sudo /usr/local/bin/docker compose build --no-cache
sudo /usr/local/bin/docker compose up -d
```

