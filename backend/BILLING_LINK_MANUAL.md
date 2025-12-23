# Ручная привязка биллинг аккаунта

## Текущая ситуация

- ✅ Проект `prompt-6a4fd` активен (ACTIVE)
- ❌ Биллинг аккаунт `0125D6-E212DE-FD3C74` проблемный и не активирован
- ⚠️  Команда `gcloud billing projects link` не работает из-за ограничений

## Решение: Привязка через Google Cloud Console

Поскольку командная строка не работает, нужно привязать биллинг аккаунт вручную через консоль:

### Шаг 1: Откройте Google Cloud Console

1. Откройте [Google Cloud Console - Billing](https://console.cloud.google.com/billing)
2. Войдите под аккаунтом `hotwell.kz@gmail.com`

### Шаг 2: Выберите проект

1. В верхней части страницы выберите проект `prompt-6a4fd`
2. Если проект не виден, используйте селектор проектов (выпадающий список)

### Шаг 3: Измените биллинг аккаунт

**Вариант A: Через меню проекта**

1. Нажмите на селектор проектов (вверху страницы)
2. Найдите проект `prompt-6a4fd`
3. Нажмите на три точки (⋮) рядом с проектом
4. Выберите **"Change billing account"** или **"Billing settings"**
5. Выберите биллинг аккаунт: **"My Billing Account 1"** (`017037-B928A3-B0D9C4`)
6. Подтвердите изменение

**Вариант B: Через Billing страницу**

1. Перейдите в [Billing](https://console.cloud.google.com/billing)
2. В левом меню выберите **"Account management"**
3. Найдите проект `prompt-6a4fd` в списке
4. Нажмите на проект
5. Нажмите **"Change billing account"**
6. Выберите **"My Billing Account 1"** (`017037-B928A3-B0D9C4`)
7. Подтвердите изменение

**Вариант C: Если видите "FIX NOW"**

1. Если на странице проекта видите кнопку **"FIX NOW"**, нажмите её
2. Следуйте инструкциям для исправления проблемы
3. Выберите рабочий биллинг аккаунт **"My Billing Account 1"**

### Шаг 4: Проверка

После привязки проверьте:

1. Статус проекта должен быть **ACTIVE**
2. Биллинг должен быть **ENABLED**
3. Проверьте через командную строку:
   ```bash
   gcloud billing projects describe prompt-6a4fd
   ```
   
   Должно показать:
   ```
   billingAccountName: billingAccounts/017037-B928A3-B0D9C4
   billingEnabled: True
   ```

### Шаг 5: Активация Firebase

После исправления биллинга:

1. Откройте [Firebase Console](https://console.firebase.google.com/project/prompt-6a4fd)
2. Убедитесь, что проект активен
3. Проверьте API ключ в [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials?project=prompt-6a4fd)
4. Убедитесь, что API ключ активен (не приостановлен)

## Альтернативный биллинг аккаунт

Если "My Billing Account 1" не работает, используйте:
- **Firebase Payment** (`019621-B7AACB-661ABA`) - также открыт (Open: True)

## Полезные ссылки

- [Google Cloud Console - Billing](https://console.cloud.google.com/billing)
- [Google Cloud Console - Projects](https://console.cloud.google.com/home/dashboard?project=prompt-6a4fd)
- [Firebase Console](https://console.firebase.google.com/project/prompt-6a4fd)

## После исправления

После успешной привязки биллинг аккаунта:

1. Проект должен автоматически активироваться
2. Firebase API ключи должны активироваться
3. Фронтенд должен начать работать
4. Подождите 2-5 минут для распространения изменений





