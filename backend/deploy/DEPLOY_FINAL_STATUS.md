# Финальный статус деплоя ShortsAI Backend в Cloud Run

## ✅ Выполнено

### 1. Проект восстановлен
- **Проект**: `prompt-6a4fd`
- **Статус**: ACTIVE
- **Биллинг**: Привязан (`017037-B928A3-B0D9C4`)

### 2. API включены
- ✅ Cloud Run API
- ✅ Artifact Registry API
- ✅ Cloud Build API
- ✅ Cloud Scheduler API
- ✅ Secret Manager API
- ✅ Storage API
- ✅ Firestore API

### 3. Artifact Registry
- **Репозиторий**: `shortsai`
- **Регион**: `us-central1`
- **Образ**: `us-central1-docker.pkg.dev/prompt-6a4fd/shortsai/shortsai-backend:latest`

### 4. Cloud Run Job (Worker)
- **Имя**: `shortsai-worker`
- **Статус**: ✅ **Задеплоен и работает**
- **Регион**: `us-central1`
- **Команда**: `npm run worker`
- **Память**: 2Gi
- **CPU**: 2

### 5. Cloud Scheduler
- **Имя**: `shortsai-worker-scheduler`
- **Статус**: ✅ **Создан и активен**
- **Расписание**: `* * * * *` (каждую минуту)
- **Service Account**: `shortsai-scheduler@prompt-6a4fd.iam.gserviceaccount.com`
- **Права**: ✅ Настроены

### 6. Firestore
- **Статус**: ✅ Активна
- **База данных**: `(default)`
- **Регион**: `nam5` (us-central)

## ⚠️ Требует настройки

### Cloud Run Service (API)

**Проблема**: Service не запускается из-за отсутствия обязательных переменных окружения:
- `TELEGRAM_API_ID`
- `TELEGRAM_API_HASH`
- `FIREBASE_SERVICE_ACCOUNT` (или отдельные переменные Firebase)

**Решение**: Добавить секреты в Secret Manager и обновить Service.

## 📋 Следующие шаги

### Шаг 1: Создать секреты в Secret Manager

```bash
PROJECT_ID="prompt-6a4fd"

# Firebase Service Account (JSON в одну строку)
# Получите JSON из Firebase Console → Project Settings → Service Accounts
echo '{"type":"service_account","project_id":"prompt-6a4fd",...}' | \
  gcloud secrets create FIREBASE_SERVICE_ACCOUNT \
    --data-file=- \
    --project=$PROJECT_ID

# Telegram API
echo -n "YOUR_TELEGRAM_API_ID" | \
  gcloud secrets create TELEGRAM_API_ID \
    --data-file=- \
    --project=$PROJECT_ID

echo -n "YOUR_TELEGRAM_API_HASH" | \
  gcloud secrets create TELEGRAM_API_HASH \
    --data-file=- \
    --project=$PROJECT_ID

# Telegram Session
echo -n "YOUR_ENCRYPTED_SESSION" | \
  gcloud secrets create TELEGRAM_SESSION_ENCRYPTED \
    --data-file=- \
    --project=$PROJECT_ID

echo -n "YOUR_64_CHAR_HEX_SECRET" | \
  gcloud secrets create TELEGRAM_SESSION_SECRET \
    --data-file=- \
    --project=$PROJECT_ID

# Google Drive (опционально)
echo -n "service-account@project.iam.gserviceaccount.com" | \
  gcloud secrets create GOOGLE_DRIVE_CLIENT_EMAIL \
    --data-file=- \
    --project=$PROJECT_ID

echo -n "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n" | \
  gcloud secrets create GOOGLE_DRIVE_PRIVATE_KEY \
    --data-file=- \
    --project=$PROJECT_ID

# Google OAuth (опционально)
echo -n "client-id.apps.googleusercontent.com" | \
  gcloud secrets create GOOGLE_CLIENT_ID \
    --data-file=- \
    --project=$PROJECT_ID

echo -n "client-secret" | \
  gcloud secrets create GOOGLE_CLIENT_SECRET \
    --data-file=- \
    --project=$PROJECT_ID

# JWT и CRON секреты
echo -n "your-jwt-secret" | \
  gcloud secrets create JWT_SECRET \
    --data-file=- \
    --project=$PROJECT_ID

echo -n "your-cron-secret" | \
  gcloud secrets create CRON_SECRET \
    --data-file=- \
    --project=$PROJECT_ID
```

**Или обновить существующие секреты:**

```bash
echo -n "NEW_VALUE" | \
  gcloud secrets versions add SECRET_NAME \
    --data-file=- \
    --project=prompt-6a4fd
```

### Шаг 2: Обновить Cloud Run Service с секретами

```bash
gcloud run services update shortsai-backend \
  --region us-central1 \
  --project prompt-6a4fd \
  --set-env-vars "NODE_ENV=production,ENABLE_CRON_SCHEDULER=false" \
  --set-secrets "FIREBASE_SERVICE_ACCOUNT=FIREBASE_SERVICE_ACCOUNT:latest,TELEGRAM_API_ID=TELEGRAM_API_ID:latest,TELEGRAM_API_HASH=TELEGRAM_API_HASH:latest,TELEGRAM_SESSION_ENCRYPTED=TELEGRAM_SESSION_ENCRYPTED:latest,TELEGRAM_SESSION_SECRET=TELEGRAM_SESSION_SECRET:latest,GOOGLE_DRIVE_CLIENT_EMAIL=GOOGLE_DRIVE_CLIENT_EMAIL:latest,GOOGLE_DRIVE_PRIVATE_KEY=GOOGLE_DRIVE_PRIVATE_KEY:latest,GOOGLE_CLIENT_ID=GOOGLE_CLIENT_ID:latest,GOOGLE_CLIENT_SECRET=GOOGLE_CLIENT_SECRET:latest,JWT_SECRET=JWT_SECRET:latest,CRON_SECRET=CRON_SECRET:latest"
```

### Шаг 3: Обновить Cloud Run Job с секретами (опционально)

```bash
gcloud run jobs update shortsai-worker \
  --region us-central1 \
  --project prompt-6a4fd \
  --set-env-vars "NODE_ENV=production" \
  --set-secrets "FIREBASE_SERVICE_ACCOUNT=FIREBASE_SERVICE_ACCOUNT:latest,TELEGRAM_API_ID=TELEGRAM_API_ID:latest,TELEGRAM_API_HASH=TELEGRAM_API_HASH:latest,TELEGRAM_SESSION_ENCRYPTED=TELEGRAM_SESSION_ENCRYPTED:latest,TELEGRAM_SESSION_SECRET=TELEGRAM_SESSION_SECRET:latest"
```

## 📊 Текущий статус

| Компонент | Статус | URL/Команда |
|-----------|--------|-------------|
| **Проект** | ✅ Активен | `prompt-6a4fd` |
| **Биллинг** | ✅ Привязан | `017037-B928A3-B0D9C4` |
| **Firestore** | ✅ Активна | `(default)` |
| **Artifact Registry** | ✅ Создан | `shortsai` |
| **Docker образ** | ✅ Собран | `us-central1-docker.pkg.dev/prompt-6a4fd/shortsai/shortsai-backend:latest` |
| **Cloud Run Service** | ⚠️ Требует секреты | Не запускается |
| **Cloud Run Job** | ✅ Работает | `shortsai-worker` |
| **Cloud Scheduler** | ✅ Активен | `shortsai-worker-scheduler` |

## 🔍 Проверка работы

### Проверить Job

```bash
# Список выполнений
gcloud run jobs executions list \
  --job shortsai-worker \
  --region us-central1 \
  --project prompt-6a4fd

# Логи последнего выполнения
gcloud run jobs executions logs read \
  --job shortsai-worker \
  --region us-central1 \
  --project prompt-6a4fd \
  --limit 50

# Ручной запуск
gcloud run jobs execute shortsai-worker \
  --region us-central1 \
  --project prompt-6a4fd
```

### Проверить Scheduler

```bash
# Описание scheduler job
gcloud scheduler jobs describe shortsai-worker-scheduler \
  --location us-central1 \
  --project prompt-6a4fd

# Ручной запуск scheduler
gcloud scheduler jobs run shortsai-worker-scheduler \
  --location us-central1 \
  --project prompt-6a4fd
```

### Проверить Service (после добавления секретов)

```bash
# Получить URL
SERVICE_URL=$(gcloud run services describe shortsai-backend \
  --platform managed \
  --region us-central1 \
  --project prompt-6a4fd \
  --format="value(status.url)")

echo "Service URL: $SERVICE_URL"

# Health check
curl $SERVICE_URL/health

# Логи
gcloud run services logs read shortsai-backend \
  --region us-central1 \
  --project prompt-6a4fd \
  --limit 50
```

## 🎯 Итог

**✅ Успешно задеплоено:**
- Cloud Run Job (Worker) - работает
- Cloud Scheduler - настроен и активен
- Автоматизация запускается каждую минуту

**⚠️ Требует настройки:**
- Cloud Run Service (API) - нужно добавить секреты

**📝 Следующий шаг:**
1. Создать секреты в Secret Manager (см. Шаг 1 выше)
2. Обновить Cloud Run Service с секретами (см. Шаг 2 выше)
3. Проверить работу Service через health check

## 🔗 Полезные ссылки

- **GCP Console**: https://console.cloud.google.com/run?project=prompt-6a4fd
- **Cloud Scheduler**: https://console.cloud.google.com/cloudscheduler?project=prompt-6a4fd
- **Secret Manager**: https://console.cloud.google.com/security/secret-manager?project=prompt-6a4fd
- **Firebase Console**: https://console.firebase.google.com/project/prompt-6a4fd

---

**Дата**: 2025-12-16
**Статус**: Деплой выполнен, требуется настройка секретов для Service

