# Исправление проблемы с биллинг аккаунтом

## Проблема

Проект `prompt-6a4fd` приостановлен из-за проблем с биллинг аккаунтом `0125D6-E212DE-FD3C74`.

Сообщение:
```
Issue with Billing Account associated with Project prompt-6a4fd
We recently noticed a problem with billing account 0125D6-E212DE-FD3C74.
As a result of this activity, your project has been suspended...
```

## Решение

### Вариант 1: Через Google Cloud Console (рекомендуется)

1. Откройте [Google Cloud Console - Billing](https://console.cloud.google.com/billing)
2. Выберите проект `prompt-6a4fd`
3. Нажмите **"FIX NOW"** (если видите это сообщение)
4. Или вручную:
   - Перейдите в **Billing** → **Account management**
   - Выберите проект `prompt-6a4fd`
   - Нажмите **"Change billing account"**
   - Выберите рабочий биллинг аккаунт:
     - `017037-B928A3-B0D9C4` - My Billing Account 1 (Open: True) ✅
     - `019621-B7AACB-661ABA` - Firebase Payment (Open: True) ✅
   - Подтвердите изменение

### Вариант 2: Через командную строку

После исправления проблемы с биллинг аккаунтом в консоли:

```bash
# Проверка доступных биллинг аккаунтов
gcloud billing accounts list

# Привязка рабочего биллинг аккаунта
gcloud billing projects link prompt-6a4fd --billing-account=019621-B7AACB-661ABA

# Или
gcloud billing projects link prompt-6a4fd --billing-account=017037-B928A3-B0D9C4

# Проверка статуса
gcloud billing projects describe prompt-6a4fd
```

### Вариант 3: Исправление проблемного биллинг аккаунта

Если вы администратор биллинг аккаунта `0125D6-E212DE-FD3C74`:

1. Откройте [Google Cloud Console - Billing](https://console.cloud.google.com/billing)
2. Выберите биллинг аккаунт `0125D6-E212DE-FD3C74`
3. Нажмите **"FIX NOW"** для исправления проблемы
4. Возможные проблемы:
   - Недостаточно средств на счету
   - Проблема с платежным методом
   - Превышен лимит расходов
   - Проблема с кредитной картой

## Доступные биллинг аккаунты

| ID | Название | Статус | Рекомендация |
|---|---|---|---|
| `0125D6-E212DE-FD3C74` | Firebase Payment | ❌ Closed | Проблемный |
| `017037-B928A3-B0D9C4` | My Billing Account 1 | ✅ Open | Рекомендуется |
| `019621-B7AACB-661ABA` | Firebase Payment | ✅ Open | Рекомендуется |
| `01A5EA-A02C07-73A08B` | Firebase Payment | ❌ Closed | Не использовать |
| `01DD6A-876501-FF1C94` | My Billing Account | ❌ Closed | Не использовать |
| `01FEFF-7A36CE-1B0D7D` | Firebase Payment | ❌ Closed | Не использовать |

## После исправления биллинга

1. **Активируйте проект**:
   - Google Cloud Console → выберите проект `prompt-6a4fd`
   - Если проект показывает предупреждение, нажмите **"Activate"**

2. **Проверьте API**:
   ```bash
   gcloud services list --enabled --project=prompt-6a4fd
   ```

3. **Проверьте Firebase**:
   - Откройте [Firebase Console](https://console.firebase.google.com/project/prompt-6a4fd)
   - Убедитесь, что проект активен
   - Проверьте API ключ в [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials?project=prompt-6a4fd)

4. **Проверьте работу фронтенда**:
   - Откройте `https://shortsai.ru`
   - Попробуйте войти
   - Проверьте консоль браузера на ошибки

## Полезные ссылки

- [Google Cloud Console - Billing](https://console.cloud.google.com/billing)
- [Firebase Console](https://console.firebase.google.com/project/prompt-6a4fd)
- [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials?project=prompt-6a4fd)

## Важно

- После исправления биллинга проект должен автоматически активироваться
- Если проект не активируется автоматически, активируйте его вручную через консоль
- API ключи Firebase должны автоматически активироваться после активации проекта
- Подождите 2-5 минут после исправления биллинга для распространения изменений





