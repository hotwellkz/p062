# Восстановление проекта prompt-6a4fd - Статус

## ✅ Выполнено

1. ✅ Проект `prompt-6a4fd` восстановлен из удаленных
2. ✅ Проект активен (ACTIVE)
3. ✅ Права Owner добавлены для `hotwell.kz@gmail.com`
4. ✅ Биллинг аккаунт привязан (`0125D6-E212DE-FD3C74`)
5. ✅ Все необходимые API включены:
   - Cloud Run API
   - Artifact Registry API
   - Cloud Build API
   - Cloud Scheduler API
   - Secret Manager API
   - Cloud Storage API
   - Firestore API
6. ✅ Firestore база данных существует (nam5, FIRESTORE_NATIVE)

## ⚠️ Текущая проблема

**Проект приостановлен (SUSPENDED)** после восстановления. Это нормально и требует активации через Google Cloud Console.

## 🔧 Решение

### Шаг 1: Активация проекта

1. Откройте [Google Cloud Console](https://console.cloud.google.com/)
2. Войдите под аккаунтом `hotwell.kz@gmail.com`
3. Выберите проект `prompt-6a4fd`
4. Если проект показывает предупреждение о приостановке, нажмите **"Activate"** или **"Restore"**

### Шаг 2: Активация биллинга (если требуется)

1. Перейдите в [Billing](https://console.cloud.google.com/billing)
2. Убедитесь, что биллинг аккаунт `0125D6-E212DE-FD3C74` активен
3. Если биллинг закрыт, активируйте его или привяжите другой

### Шаг 3: Настройка секретов

После активации проекта выполните:

```powershell
cd backend
.\setup-secrets.ps1
```

Или вручную создайте секреты:

```bash
# Telegram API
echo -n "23896635" | gcloud secrets create TELEGRAM_API_ID --data-file=- --project=prompt-6a4fd
echo -n "f4d3ff7cce4d9b8bc6ea2388f32b5973" | gcloud secrets create TELEGRAM_API_HASH --data-file=- --project=prompt-6a4fd
echo -n "fac61ac113cceee13495768b345b3ef1e0683459150839779447955ac1d481f6" | gcloud secrets create TELEGRAM_SESSION_SECRET --data-file=- --project=prompt-6a4fd

# JWT и CRON
echo -n "dev_jwt_secret_129384712983471" | gcloud secrets create JWT_SECRET --data-file=- --project=prompt-6a4fd
echo -n "dev_cron_secret_982734987" | gcloud secrets create CRON_SECRET --data-file=- --project=prompt-6a4fd
```

### Шаг 4: Деплой

После активации проекта и настройки секретов:

```bash
cd backend
bash deploy/deploy_cloud_run.sh
```

## 📋 Проверка статуса

Проверьте статус проекта:

```bash
gcloud projects describe prompt-6a4fd --format="value(projectId,name,lifecycleState)"
```

Должно быть: `prompt-6a4fd	Prompt	ACTIVE`

## 🔍 Полезные команды

### Проверка биллинга
```bash
gcloud billing projects describe prompt-6a4fd
```

### Проверка API
```bash
gcloud services list --enabled --project=prompt-6a4fd --filter="name:run.googleapis.com OR name:firestore.googleapis.com"
```

### Проверка Firestore
```bash
gcloud firestore databases list --project=prompt-6a4fd
```

### Проверка секретов (после активации)
```bash
gcloud secrets list --project=prompt-6a4fd
```

## ⏱️ Время активации

Обычно проект активируется в течение 5-15 минут после восстановления. Если проект не активируется автоматически:

1. Проверьте биллинг аккаунт в [Google Cloud Console](https://console.cloud.google.com/billing)
2. Убедитесь, что биллинг аккаунт активен и имеет достаточный баланс
3. Попробуйте привязать другой биллинг аккаунт

## 📞 Поддержка

Если проект не активируется:
1. Проверьте статус в [Google Cloud Console](https://console.cloud.google.com/)
2. Обратитесь в [Google Cloud Support](https://cloud.google.com/support)
3. Убедитесь, что биллинг аккаунт активен





