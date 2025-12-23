# Тестирование Dual-Auth (Firebase + Local JWT)

## Описание

Backend теперь поддерживает два типа авторизации:
1. **Firebase ID Token** (основной метод) - для пользователей фронтенда
2. **Local JWT** (fallback) - для dev/admin доступа

## Генерация токенов

### 1. Локальный JWT токен (для тестирования)

```powershell
# В папке backend
cd backend
$env:JWT_SECRET='dev_jwt_secret_129384712983471'
node -e "console.log(require('jsonwebtoken').sign({role:'admin'}, process.env.JWT_SECRET || 'dev_jwt_secret_129384712983471'))"
```

**Пример токена:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW4iLCJpYXQiOjE3NjYzMzM4NzZ9.3Crm6UwXwBHYH6Uwc02u8bG8Dbv0Dz29ScNXY1xhF2w
```

### 2. Firebase ID Token

Получить из браузера:
1. Откройте https://shortsai.ru
2. Авторизуйтесь
3. Откройте DevTools → Network
4. Найдите любой запрос к API
5. Скопируйте значение из заголовка `Authorization: Bearer <token>`

## Тестирование endpoint

### Тест 1: Локальный JWT токен

```powershell
# PowerShell
$token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW4iLCJpYXQiOjE3NjYzMzM4NzZ9.3Crm6UwXwBHYH6Uwc02u8bG8Dbv0Dz29ScNXY1xhF2w"
$body = '{\"channelId\":\"test\",\"url\":\"https://getvideo.syntxai.net/IDF8F06K0bmB\"}'
curl.exe -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer $token" `
  -d $body
```

**Ожидаемый результат:**
- HTTP 200 или 202 (если все параметры валидны)
- ИЛИ HTTP 400/500 с описанием ошибки (но НЕ 401 INVALID_TOKEN!)

### Тест 2: Firebase ID Token

```powershell
# PowerShell
$firebaseToken = "<ваш_firebase_token_из_браузера>"
$body = '{\"channelId\":\"test\",\"url\":\"https://getvideo.syntxai.net/IDF8F06K0bmB\"}'
curl.exe -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer $firebaseToken" `
  -d $body
```

**Ожидаемый результат:**
- HTTP 200 или 202 (если все параметры валидны)
- ИЛИ HTTP 400/500 с описанием ошибки

### Тест 3: Невалидный токен

```powershell
curl.exe -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer invalid_token_12345" `
  -d '{\"channelId\":\"test\"}'
```

**Ожидаемый результат:**
- HTTP 401 Unauthorized
- Body: `{"error":"Unauthorized","errorCode":"INVALID_JWT_TOKEN",...}`

### Тест 4: JWT без роли admin

```powershell
# Генерируем токен без role:admin
cd backend
$env:JWT_SECRET='dev_jwt_secret_129384712983471'
$tokenNoAdmin = node -e "console.log(require('jsonwebtoken').sign({role:'user'}, process.env.JWT_SECRET || 'dev_jwt_secret_129384712983471'))"

# Тестируем
curl.exe -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer $tokenNoAdmin" `
  -d '{\"channelId\":\"test\"}'
```

**Ожидаемый результат:**
- HTTP 403 Forbidden
- Body: `{"error":"Forbidden","errorCode":"INSUFFICIENT_PERMISSIONS","message":"Admin role required for this endpoint"}`

## Проверка логов

После запроса проверьте логи контейнера на Synology:

```bash
ssh adminv@192.168.100.222
sudo docker logs shorts-backend --tail 50 | grep -i "authRequired"
```

Должны быть логи вида:
- `authRequired: using Firebase authentication` или
- `authRequired: using local JWT authentication`
- `authRequired: local JWT token verified successfully` (для JWT)
- `authRequired: Firebase token verified successfully` (для Firebase)

