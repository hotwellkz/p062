# Деплой ShortsAI Backend в Google Cloud Run

## Обзор

Этот документ описывает процесс деплоя ShortsAI Backend в Google Cloud Run с использованием:
- **Cloud Run Service** - для HTTP API
- **Cloud Run Job** - для worker задач (автоматизация)
- **Cloud Scheduler** - для запуска Job каждую минуту

## Архитектура

```
Cloud Scheduler (каждую минуту)
    ↓
Cloud Run Job (worker)
    ↓
    ├─→ processAutoSendTick() - автоотправка промптов
    └─→ processBlottataTick() - мониторинг Blottata

Cloud Run Service (API)
    ↓
    ├─→ /health - health check
    ├─→ /api/* - REST API endpoints
    └─→ /api/cron/* - cron endpoints (для ручного запуска)
```

## Предварительные требования

1. **GCP проект восстановлен**: `prompt-6a4fd`
2. **Биллинг привязан** (критично!)
3. **Firebase/Firestore активна**
4. **gcloud CLI установлен и настроен**

## Шаг 1: Привязка биллинга

**ВАЖНО**: Без биллинга невозможно включить API и выполнить деплой.

Выполните команду для привязки биллинга (выберите один из доступных):

```bash
# Список доступных billing accounts
gcloud billing accounts list

# Привязка биллинга (замените BILLING_ACCOUNT_ID на реальный ID)
gcloud billing projects link prompt-6a4fd --billing-account=BILLING_ACCOUNT_ID

# Проверка
gcloud billing projects describe prompt-6a4fd
```

**Доступные billing accounts:**
- `0125D6-E212DE-FD3C74` - Firebase Payment
- `017037-B928A3-B0D9C4` - My Billing Account 1
- `019621-B7AACB-661ABA` - Firebase Payment
- `01A5EA-A02C07-73A08B` - Firebase Payment
- `01DD6A-876501-FF1C94` - My Billing Account
- `01FEFF-7A36CE-1B0D7D` - Firebase Payment

**Пример:**
```bash
gcloud billing projects link prompt-6a4fd --billing-account=01DD6A-876501-FF1C94
```

## Шаг 2: Включение API

После привязки биллинга включите необходимые API:

```bash
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  cloudscheduler.googleapis.com \
  secretmanager.googleapis.com \
  storage.googleapis.com \
  firestore.googleapis.com \
  --project=prompt-6a4fd
```

## Шаг 3: Настройка Secret Manager

Перед деплоем необходимо создать секреты в Secret Manager:

```bash
PROJECT_ID="prompt-6a4fd"

# Firebase Service Account (JSON в одну строку)
echo '{"type":"service_account",...}' | gcloud secrets create FIREBASE_SERVICE_ACCOUNT \
  --data-file=- --project=$PROJECT_ID

# Telegram API
echo -n "YOUR_TELEGRAM_API_ID" | gcloud secrets create TELEGRAM_API_ID \
  --data-file=- --project=$PROJECT_ID

echo -n "YOUR_TELEGRAM_API_HASH" | gcloud secrets create TELEGRAM_API_HASH \
  --data-file=- --project=$PROJECT_ID

echo -n "YOUR_ENCRYPTED_SESSION" | gcloud secrets create TELEGRAM_SESSION_ENCRYPTED \
  --data-file=- --project=$PROJECT_ID

echo -n "YOUR_64_CHAR_HEX_SECRET" | gcloud secrets create TELEGRAM_SESSION_SECRET \
  --data-file=- --project=$PROJECT_ID

# Google Drive
echo -n "service-account@project.iam.gserviceaccount.com" | gcloud secrets create GOOGLE_DRIVE_CLIENT_EMAIL \
  --data-file=- --project=$PROJECT_ID

echo -n "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n" | gcloud secrets create GOOGLE_DRIVE_PRIVATE_KEY \
  --data-file=- --project=$PROJECT_ID

# Google OAuth
echo -n "client-id.apps.googleusercontent.com" | gcloud secrets create GOOGLE_CLIENT_ID \
  --data-file=- --project=$PROJECT_ID

echo -n "client-secret" | gcloud secrets create GOOGLE_CLIENT_SECRET \
  --data-file=- --project=$PROJECT_ID

# JWT и CRON секреты
echo -n "your-jwt-secret" | gcloud secrets create JWT_SECRET \
  --data-file=- --project=$PROJECT_ID

echo -n "your-cron-secret" | gcloud secrets create CRON_SECRET \
  --data-file=- --project=$PROJECT_ID
```

**Или обновить существующие секреты:**

```bash
echo -n "NEW_VALUE" | gcloud secrets versions add SECRET_NAME \
  --data-file=- --project=$PROJECT_ID
```

## Шаг 4: Деплой

### Автоматический деплой (рекомендуется)

```bash
cd backend
bash deploy/deploy_cloud_run.sh
```

### Ручной деплой

#### 4.1 Создание Artifact Registry

```bash
gcloud artifacts repositories create shortsai \
  --repository-format=docker \
  --location=us-central1 \
  --description="ShortsAI Backend Docker images" \
  --project=prompt-6a4fd
```

#### 4.2 Сборка и загрузка образа

```bash
cd backend
gcloud builds submit \
  --tag us-central1-docker.pkg.dev/prompt-6a4fd/shortsai/shortsai-backend:latest \
  --project=prompt-6a4fd \
  --region=us-central1
```

#### 4.3 Деплой Cloud Run Service (API)

```bash
gcloud run deploy shortsai-backend \
  --image us-central1-docker.pkg.dev/prompt-6a4fd/shortsai/shortsai-backend:latest \
  --platform managed \
  --region us-central1 \
  --project prompt-6a4fd \
  --allow-unauthenticated \
  --port 8080 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --max-instances 10 \
  --min-instances 0 \
  --set-env-vars "NODE_ENV=production,ENABLE_CRON_SCHEDULER=false" \
  --set-secrets "FIREBASE_SERVICE_ACCOUNT=FIREBASE_SERVICE_ACCOUNT:latest,TELEGRAM_API_ID=TELEGRAM_API_ID:latest,TELEGRAM_API_HASH=TELEGRAM_API_HASH:latest,TELEGRAM_SESSION_ENCRYPTED=TELEGRAM_SESSION_ENCRYPTED:latest,TELEGRAM_SESSION_SECRET=TELEGRAM_SESSION_SECRET:latest,GOOGLE_DRIVE_CLIENT_EMAIL=GOOGLE_DRIVE_CLIENT_EMAIL:latest,GOOGLE_DRIVE_PRIVATE_KEY=GOOGLE_DRIVE_PRIVATE_KEY:latest,GOOGLE_CLIENT_ID=GOOGLE_CLIENT_ID:latest,GOOGLE_CLIENT_SECRET=GOOGLE_CLIENT_SECRET:latest,JWT_SECRET=JWT_SECRET:latest,CRON_SECRET=CRON_SECRET:latest"
```

#### 4.4 Деплой Cloud Run Job (Worker)

```bash
gcloud run jobs deploy shortsai-worker \
  --image us-central1-docker.pkg.dev/prompt-6a4fd/shortsai/shortsai-backend:latest \
  --region us-central1 \
  --project prompt-6a4fd \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --max-retries 1 \
  --task-timeout 300 \
  --command "npm" \
  --args "run,worker" \
  --set-env-vars "NODE_ENV=production" \
  --set-secrets "FIREBASE_SERVICE_ACCOUNT=FIREBASE_SERVICE_ACCOUNT:latest,TELEGRAM_API_ID=TELEGRAM_API_ID:latest,TELEGRAM_API_HASH=TELEGRAM_API_HASH:latest,TELEGRAM_SESSION_ENCRYPTED=TELEGRAM_SESSION_ENCRYPTED:latest,TELEGRAM_SESSION_SECRET=TELEGRAM_SESSION_SECRET:latest,GOOGLE_DRIVE_CLIENT_EMAIL=GOOGLE_DRIVE_CLIENT_EMAIL:latest,GOOGLE_DRIVE_PRIVATE_KEY=GOOGLE_DRIVE_PRIVATE_KEY:latest,GOOGLE_CLIENT_ID=GOOGLE_CLIENT_ID:latest,GOOGLE_CLIENT_SECRET=GOOGLE_CLIENT_SECRET:latest"
```

#### 4.5 Создание Service Account для Scheduler

```bash
# Создание service account
gcloud iam service-accounts create shortsai-scheduler \
  --display-name="ShortsAI Scheduler" \
  --project=prompt-6a4fd

# Выдача прав на запуск Job
gcloud run jobs add-iam-policy-binding shortsai-worker \
  --region=us-central1 \
  --member="serviceAccount:shortsai-scheduler@prompt-6a4fd.iam.gserviceaccount.com" \
  --role="roles/run.invoker" \
  --project=prompt-6a4fd
```

#### 4.6 Создание Cloud Scheduler Job

```bash
JOB_URI="https://us-central1-run.googleapis.com/v2/projects/prompt-6a4fd/locations/us-central1/jobs/shortsai-worker:run"

gcloud scheduler jobs create http shortsai-worker-scheduler \
  --location us-central1 \
  --project prompt-6a4fd \
  --schedule "* * * * *" \
  --uri "$JOB_URI" \
  --http-method POST \
  --oauth-service-account-email "shortsai-scheduler@prompt-6a4fd.iam.gserviceaccount.com" \
  --time-zone "UTC" \
  --attempt-deadline 300s
```

## Шаг 5: Проверка деплоя

### Проверка Service

```bash
# Получить URL сервиса
SERVICE_URL=$(gcloud run services describe shortsai-backend \
  --platform managed \
  --region us-central1 \
  --project prompt-6a4fd \
  --format="value(status.url)")

echo "Service URL: $SERVICE_URL"

# Health check
curl $SERVICE_URL/health
```

### Проверка Job

```bash
# Список выполнений Job
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
```

### Проверка Scheduler

```bash
# Список scheduler jobs
gcloud scheduler jobs list \
  --location us-central1 \
  --project prompt-6a4fd

# Ручной запуск scheduler job
gcloud scheduler jobs run shortsai-worker-scheduler \
  --location us-central1 \
  --project prompt-6a4fd
```

## Полезные команды

### Просмотр логов

```bash
# Логи Service
gcloud run services logs read shortsai-backend \
  --region us-central1 \
  --project prompt-6a4fd \
  --limit 50

# Логи Job
gcloud run jobs executions logs read \
  --job shortsai-worker \
  --region us-central1 \
  --project prompt-6a4fd \
  --limit 50
```

### Ручной запуск Job

```bash
# Запуск Job вручную
gcloud run jobs execute shortsai-worker \
  --region us-central1 \
  --project prompt-6a4fd
```

### Обновление деплоя

```bash
# Пересборка образа
cd backend
gcloud builds submit \
  --tag us-central1-docker.pkg.dev/prompt-6a4fd/shortsai/shortsai-backend:latest \
  --project=prompt-6a4fd \
  --region=us-central1

# Обновление Service
gcloud run services update shortsai-backend \
  --image us-central1-docker.pkg.dev/prompt-6a4fd/shortsai/shortsai-backend:latest \
  --region us-central1 \
  --project prompt-6a4fd

# Обновление Job
gcloud run jobs update shortsai-worker \
  --image us-central1-docker.pkg.dev/prompt-6a4fd/shortsai/shortsai-backend:latest \
  --region us-central1 \
  --project prompt-6a4fd
```

## Структура Worker

Worker (`src/worker.ts`) выполняет:
1. **Acquire Lock** - получает distributed lock в Firestore для предотвращения параллельных запусков
2. **processAutoSendTick()** - обработка автоотправки промптов
3. **processBlottataTick()** - мониторинг и обработка Blottata файлов
4. **Release Lock** - освобождает lock
5. **Exit** - завершает работу (Job завершается)

Lock хранится в Firestore коллекции `locks` с документом `worker` и TTL 5 минут.

## Мониторинг

### Cloud Monitoring

- **Service metrics**: CPU, Memory, Request count, Latency
- **Job metrics**: Execution count, Success/Failure rate, Duration
- **Scheduler metrics**: Job runs, Success/Failure

### Логи

Все логи доступны в Cloud Logging:
- Service logs: `resource.type="cloud_run_revision"`
- Job logs: `resource.type="cloud_run_job"`

## Troubleshooting

### Job не запускается

1. Проверьте права Scheduler service account:
```bash
gcloud run jobs get-iam-policy shortsai-worker \
  --region us-central1 \
  --project prompt-6a4fd
```

2. Проверьте логи Scheduler:
```bash
gcloud scheduler jobs describe shortsai-worker-scheduler \
  --location us-central1 \
  --project prompt-6a4fd
```

### Worker зависает

1. Проверьте lock в Firestore:
```bash
# В Firebase Console проверьте коллекцию locks, документ worker
```

2. Увеличьте timeout в Job:
```bash
gcloud run jobs update shortsai-worker \
  --task-timeout 600 \
  --region us-central1 \
  --project prompt-6a4fd
```

### Service не отвечает

1. Проверьте health endpoint:
```bash
curl https://SERVICE_URL/health
```

2. Проверьте логи:
```bash
gcloud run services logs read shortsai-backend \
  --region us-central1 \
  --project prompt-6a4fd
```

## Стоимость

Примерная стоимость (при активном использовании):
- **Cloud Run Service**: ~$0.40/миллион запросов + $0.00002400/GB-секунда
- **Cloud Run Job**: ~$0.00002400/GB-секунда (только во время выполнения)
- **Cloud Scheduler**: бесплатно до 3 jobs
- **Artifact Registry**: ~$0.10/GB/месяц
- **Secret Manager**: ~$0.06/секрет/месяц

При минимальном использовании (1 job в минуту, ~30 секунд выполнения):
- Job: ~$0.01-0.02/месяц
- Service: зависит от трафика API

## Безопасность

1. **Секреты**: Все секреты хранятся в Secret Manager
2. **IAM**: Service accounts с минимальными правами
3. **Lock**: Distributed lock предотвращает параллельные запуски
4. **Health check**: Endpoint `/health` для мониторинга

## Обновление

Для обновления кода:
1. Внесите изменения в код
2. Запустите `bash deploy/deploy_cloud_run.sh`
3. Или выполните шаги 4.2-4.4 вручную

## Контакты

При проблемах проверьте:
1. Биллинг привязан
2. API включены
3. Секреты созданы
4. Service accounts имеют права
5. Логи в Cloud Logging

