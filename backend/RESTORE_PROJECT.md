# Восстановление проекта prompt-6a4fd в Cloud Run

## Текущая ситуация

- ✅ Проект `prompt-6a4fd` существует (Project Number: 905027425668)
- ✅ gcloud CLI установлен и настроен
- ❌ Текущий аккаунт `hotwell.kz@gmail.com` не имеет прав доступа к проекту
- ❌ Биллинг не привязан

## Шаг 1: Восстановление доступа к проекту

### Вариант A: Через Firebase Console (рекомендуется)

1. Откройте [Firebase Console](https://console.firebase.google.com/)
2. Войдите под аккаунтом, который является владельцем проекта `prompt-6a4fd`
3. Перейдите в проект `prompt-6a4fd`
4. Откройте **Project Settings** → **Users and permissions**
5. Добавьте `hotwell.kz@gmail.com` с ролью **Owner** или **Editor**

### Вариант B: Через Google Cloud Console

1. Откройте [Google Cloud Console](https://console.cloud.google.com/)
2. Войдите под аккаунтом-владельцем проекта
3. Перейдите в **IAM & Admin** → **IAM**
4. Нажмите **Grant Access**
5. Добавьте `hotwell.kz@gmail.com` с ролью **Owner** или **Editor**

### Вариант C: Авторизация под другим аккаунтом

Если у вас есть доступ к другому аккаунту:

```bash
gcloud auth login
# Выберите аккаунт-владельца проекта
gcloud config set project prompt-6a4fd
```

## Шаг 2: Привязка биллинга

После восстановления доступа выполните:

```bash
# Проверьте доступные billing accounts
gcloud billing accounts list

# Привяжите биллинг (выберите один из доступных)
gcloud billing projects link prompt-6a4fd --billing-account=01DD6A-876501-FF1C94
```

**Доступные billing accounts:**
- `0125D6-E212DE-FD3C74` - Firebase Payment
- `017037-B928A3-B0D9C4` - My Billing Account 1
- `019621-B7AACB-661ABA` - Firebase Payment
- `01A5EA-A02C07-73A08B` - Firebase Payment
- `01DD6A-876501-FF1C94` - My Billing Account (рекомендуется)
- `01FEFF-7A36CE-1B0D7D` - Firebase Payment

## Шаг 3: Включение API

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

## Шаг 4: Проверка Firestore

```bash
# Проверка существующей базы данных
gcloud firestore databases list --project=prompt-6a4fd

# Если базы нет, создайте её
gcloud firestore databases create \
  --location=us-central1 \
  --type=firestore-native \
  --project=prompt-6a4fd
```

## Шаг 5: Настройка секретов

Создайте секреты в Secret Manager из переменных окружения:

```bash
cd backend

# Telegram API
echo -n "YOUR_TELEGRAM_API_ID" | gcloud secrets create TELEGRAM_API_ID \
  --data-file=- --project=prompt-6a4fd

echo -n "YOUR_TELEGRAM_API_HASH" | gcloud secrets create TELEGRAM_API_HASH \
  --data-file=- --project=prompt-6a4fd

echo -n "YOUR_TELEGRAM_SESSION_SECRET" | gcloud secrets create TELEGRAM_SESSION_SECRET \
  --data-file=- --project=prompt-6a4fd

# JWT и CRON
echo -n "YOUR_JWT_SECRET" | gcloud secrets create JWT_SECRET \
  --data-file=- --project=prompt-6a4fd

echo -n "YOUR_CRON_SECRET" | gcloud secrets create CRON_SECRET \
  --data-file=- --project=prompt-6a4fd

# Google Drive (если используется)
echo -n "service-account@project.iam.gserviceaccount.com" | gcloud secrets create GOOGLE_DRIVE_CLIENT_EMAIL \
  --data-file=- --project=prompt-6a4fd

# Firebase Service Account (если используется JSON)
echo -n '{"type":"service_account",...}' | gcloud secrets create FIREBASE_SERVICE_ACCOUNT \
  --data-file=- --project=prompt-6a4fd
```

**Или используйте значения из `.env` файла:**

```bash
# Читайте значения из .env и создавайте секреты
source .env  # или используйте PowerShell: Get-Content .env
```

## Шаг 6: Автоматический деплой

После восстановления доступа запустите скрипт восстановления:

### Windows (PowerShell):
```powershell
cd backend
.\restore-cloud-run.ps1
```

### Linux/Mac (Bash):
```bash
cd backend
bash restore-cloud-run.sh
```

### Или используйте готовый скрипт деплоя:
```bash
cd backend
bash deploy/deploy_cloud_run.sh
```

## Шаг 7: Проверка деплоя

После деплоя проверьте:

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

## Альтернатива: Создание нового проекта

Если восстановление доступа невозможно, можно создать новый проект:

```bash
# Создать новый проект
gcloud projects create YOUR-NEW-PROJECT-ID --name="ShortsAI Backend"

# Установить проект
gcloud config set project YOUR-NEW-PROJECT-ID

# Привязать биллинг
gcloud billing projects link YOUR-NEW-PROJECT-ID --billing-account=01DD6A-876501-FF1C94

# Затем выполните шаги 3-7 выше
```

**ВАЖНО:** При создании нового проекта нужно будет:
1. Создать новую Firebase базу данных
2. Настроить все переменные окружения заново
3. Обновить конфигурацию фронтенда

## Полезные команды

### Проверка статуса проекта
```bash
gcloud projects describe prompt-6a4fd
gcloud billing projects describe prompt-6a4fd
```

### Просмотр логов
```bash
gcloud run services logs read shortsai-backend \
  --region us-central1 \
  --project prompt-6a4fd
```

### Обновление деплоя
```bash
cd backend
bash deploy/deploy_cloud_run.sh
```

## Контакты и поддержка

Если возникли проблемы:
1. Проверьте права доступа в IAM
2. Убедитесь, что биллинг привязан
3. Проверьте логи в Cloud Logging
4. Убедитесь, что все API включены





