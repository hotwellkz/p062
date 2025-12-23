# Статус биллинга проекта prompt-6a4fd

## Текущая ситуация

- ✅ Проект `prompt-6a4fd` восстановлен и активен
- ✅ Биллинг аккаунт `01DD6A-876501-FF1C94` привязан к проекту
- ⚠️  Биллинг не активирован (`billingEnabled: false`)
- ✅ Firestore база данных существует (nam5, FIRESTORE_NATIVE)

## Проблема

Биллинг аккаунт привязан, но не активирован. Это может быть из-за:
1. Биллинг аккаунт закрыт или требует активации
2. Необходимо активировать биллинг через Google Cloud Console

## Решение

### Вариант 1: Активация через Google Cloud Console

1. Откройте [Google Cloud Console - Billing](https://console.cloud.google.com/billing)
2. Выберите проект `prompt-6a4fd`
3. Убедитесь, что биллинг аккаунт `01DD6A-876501-FF1C94` активен
4. Если биллинг закрыт, активируйте его

### Вариант 2: Использование другого биллинг аккаунта

Если текущий биллинг аккаунт не работает, используйте другой:

```bash
# Список доступных биллинг аккаунтов
gcloud billing accounts list

# Привязка другого аккаунта
gcloud billing projects link prompt-6a4fd --billing-account=BILLING_ACCOUNT_ID
```

**Доступные биллинг аккаунты:**
- `0125D6-E212DE-FD3C74` - Firebase Payment
- `017037-B928A3-B0D9C4` - My Billing Account 1
- `019621-B7AACB-661ABA` - Firebase Payment
- `01A5EA-A02C07-73A08B` - Firebase Payment
- `01DD6A-876501-FF1C94` - My Billing Account (текущий)
- `01FEFF-7A36CE-1B0D7D` - Firebase Payment

### Вариант 3: Ожидание активации

Иногда после восстановления проекта биллинг активируется автоматически через несколько минут. Подождите 5-10 минут и попробуйте снова включить API.

## После активации биллинга

Выполните команды для включения API:

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

Затем продолжите с деплоем:

```bash
cd backend
bash deploy/deploy_cloud_run.sh
```





