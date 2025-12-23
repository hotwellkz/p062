# Остановка Cloud Run - Инструкция

## Цель

Остановить все Cloud Run сервисы, чтобы работал только backend на Synology. Оба используют одну Firebase базу данных, поэтому нужно избежать конфликтов.

## Текущая ситуация

- ✅ Backend работает на Synology: `https://api.hotwell.synology.me`
- ⚠️  Cloud Run сервисы могут быть активны в проекте `prompt-6a4fd`
- ⚠️  Проект приостановлен после восстановления

## Шаг 1: Активация проекта

Если проект приостановлен:

1. Откройте [Google Cloud Console](https://console.cloud.google.com/)
2. Выберите проект `prompt-6a4fd`
3. Активируйте проект (если требуется)

## Шаг 2: Остановка Cloud Run сервисов

### Вариант A: Через скрипт (рекомендуется)

```powershell
cd backend
.\stop-cloud-run.ps1
```

### Вариант B: Через Google Cloud Console

1. Откройте [Cloud Run](https://console.cloud.google.com/run)
2. Выберите проект `prompt-6a4fd`
3. Для каждого сервиса:
   - Нажмите на сервис
   - Нажмите "DELETE" или "STOP"
   - Подтвердите удаление

4. Откройте [Cloud Run Jobs](https://console.cloud.google.com/run/jobs)
5. Удалите все Jobs (например, `shortsai-worker`)

6. Откройте [Cloud Scheduler](https://console.cloud.google.com/cloudscheduler)
7. Удалите все Scheduler Jobs (например, `shortsai-worker-scheduler`)

### Вариант C: Через командную строку

После активации проекта выполните:

```bash
PROJECT_ID="prompt-6a4fd"
REGION="us-central1"

# Удалить все Cloud Run Services
gcloud run services list --project=$PROJECT_ID --region=$REGION --format="value(metadata.name)" | \
  xargs -I {} gcloud run services delete {} --region=$REGION --project=$PROJECT_ID --quiet

# Удалить все Cloud Run Jobs
gcloud run jobs list --project=$PROJECT_ID --region=$REGION --format="value(metadata.name)" | \
  xargs -I {} gcloud run jobs delete {} --region=$REGION --project=$PROJECT_ID --quiet

# Удалить все Cloud Scheduler Jobs
gcloud scheduler jobs list --project=$PROJECT_ID --location=$REGION --format="value(name)" | \
  xargs -I {} gcloud scheduler jobs delete {} --location=$REGION --project=$PROJECT_ID --quiet
```

## Шаг 3: Проверка

Проверьте, что Cloud Run сервисы остановлены:

```bash
# Список сервисов (должен быть пуст)
gcloud run services list --project=prompt-6a4fd --region=us-central1

# Список Jobs (должен быть пуст)
gcloud run jobs list --project=prompt-6a4fd --region=us-central1

# Список Scheduler Jobs (должен быть пуст)
gcloud scheduler jobs list --project=prompt-6a4fd --location=us-central1
```

## Шаг 4: Проверка работы Synology backend

Убедитесь, что backend на Synology работает:

```bash
# Health check
curl https://api.hotwell.synology.me/health

# Должен вернуть: {"ok":true}
```

## Важно

- ✅ Firebase база данных остается активной и используется только Synology backend
- ✅ Cloud Run сервисы можно восстановить позже, если понадобится
- ✅ Секреты в Secret Manager остаются (можно использовать позже)
- ✅ Docker образы в Artifact Registry остаются (можно использовать позже)

## Восстановление Cloud Run (если понадобится)

Если нужно будет восстановить Cloud Run:

```bash
cd backend
bash deploy/deploy_cloud_run.sh
```

## Мониторинг

После остановки Cloud Run проверьте:

1. **Firebase Console**: Убедитесь, что данные обновляются только от Synology backend
2. **Cloud Logging**: Проверьте, что нет активности от Cloud Run сервисов
3. **Billing**: Cloud Run больше не будет генерировать расходы

## Полезные команды

### Проверка активных сервисов
```bash
gcloud run services list --project=prompt-6a4fd --region=us-central1
```

### Проверка активных Jobs
```bash
gcloud run jobs list --project=prompt-6a4fd --region=us-central1
```

### Проверка Scheduler Jobs
```bash
gcloud scheduler jobs list --project=prompt-6a4fd --location=us-central1
```

### Просмотр логов (если сервисы еще работают)
```bash
gcloud run services logs read SERVICE_NAME --region=us-central1 --project=prompt-6a4fd
```





