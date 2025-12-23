# Исправление ошибки Firebase API Key Suspended

## Проблема

Ошибка авторизации:
```
Firebase: Error (auth/permission-denied:-consumer-'api-key:aizasyctag7ftgy7esyeqf1wxl0ei7huo5ls0sq'-has-been-suspended.)
```

## Причина

Firebase API ключ был приостановлен из-за приостановки проекта `prompt-6a4fd` после восстановления из удаленных.

## Решение

### Шаг 1: Активация проекта в Firebase Console

1. Откройте [Firebase Console](https://console.firebase.google.com/)
2. Войдите под аккаунтом `hotwell.kz@gmail.com`
3. Выберите проект `prompt-6a4fd`
4. Если проект показывает предупреждение о приостановке:
   - Нажмите **"Activate"** или **"Restore"**
   - Подтвердите активацию

### Шаг 2: Проверка API ключа

1. В Firebase Console перейдите в **Project Settings** (⚙️)
2. Откройте вкладку **General**
3. Найдите секцию **Your apps** → выберите ваш Web app
4. Проверьте **API Key** - должен быть `AIzaSyCtAg7fTGY7EsyEQf1WXl0ei7HUO5ls0sQ`

### Шаг 3: Активация API ключа в Google Cloud Console

1. Откройте [Google Cloud Console - APIs & Services - Credentials](https://console.cloud.google.com/apis/credentials?project=prompt-6a4fd)
2. Найдите API ключ `AIzaSyCtAg7fTGY7EsyEQf1WXl0ei7HUO5ls0sQ`
3. Если ключ показывает статус "Suspended" или "Restricted":
   - Нажмите на ключ
   - Проверьте **API restrictions** и **Application restrictions**
   - Если нужно, снимите ограничения или настройте правильно
   - Сохраните изменения

### Шаг 4: Проверка Firebase Authentication

1. В Firebase Console перейдите в **Authentication**
2. Убедитесь, что **Sign-in method** включен:
   - **Email/Password** - должен быть включен
   - **Google** - если используется, должен быть включен
3. Если методы отключены, включите их

### Шаг 5: Пересоздание API ключа (если не помогло)

Если API ключ не активируется:

1. В [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials?project=prompt-6a4fd)
2. Создайте новый API ключ:
   - Нажмите **"+ CREATE CREDENTIALS"** → **"API key"**
   - Скопируйте новый ключ
3. Обновите ключ в Firebase Console:
   - Firebase Console → Project Settings → General
   - Выберите ваш Web app
   - Обновите **API Key** на новый
4. Обновите переменную окружения в Netlify:
   - Netlify → Site settings → Environment variables
   - Обновите `VITE_FIREBASE_API_KEY` на новый ключ
   - Перезапустите деплой

### Шаг 6: Проверка переменных окружения в Netlify

Убедитесь, что в Netlify установлены правильные переменные:

1. Откройте [Netlify Dashboard](https://app.netlify.com/)
2. Выберите ваш сайт
3. Перейдите в **Site settings** → **Environment variables**
4. Проверьте наличие и значения:
   ```
   VITE_FIREBASE_API_KEY=AIzaSyCtAg7fTGY7EsyEQf1WXl0ei7HUO5ls0sQ
   VITE_FIREBASE_AUTH_DOMAIN=prompt-6a4fd.firebaseapp.com
   VITE_FIREBASE_PROJECT_ID=prompt-6a4fd
   VITE_FIREBASE_STORAGE_BUCKET=prompt-6a4fd.firebasestorage.app
   VITE_FIREBASE_MESSAGING_SENDER_ID=905027425668
   VITE_FIREBASE_APP_ID=1:905027425668:web:38f58912370df2c2be39d1
   ```
5. Если переменные не совпадают, обновите их
6. После обновления перезапустите деплой:
   - **Deploys** → **Trigger deploy** → **Clear cache and deploy site**

## Быстрое решение

Если проект уже активирован, но API ключ все еще приостановлен:

1. **Google Cloud Console** → [APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials?project=prompt-6a4fd)
2. Найдите API ключ `AIzaSyCtAg7fTGY7EsyEQf1WXl0ei7HUO5ls0sQ`
3. Нажмите на ключ → **Edit**
4. Убедитесь, что **API restrictions** включает:
   - Firebase Authentication API
   - Cloud Firestore API
   - Firebase Realtime Database API (если используется)
5. Сохраните изменения
6. Подождите 1-2 минуты для распространения изменений

## Проверка после исправления

1. Откройте фронтенд: `https://shortsai.ru`
2. Попробуйте войти
3. Проверьте консоль браузера (F12) на наличие ошибок
4. Если ошибка сохраняется, проверьте:
   - Статус проекта в Firebase Console
   - Статус API ключа в Google Cloud Console
   - Переменные окружения в Netlify

## Альтернативное решение: Пересоздание Web App

Если ничего не помогает:

1. Firebase Console → Project Settings → General
2. В секции **Your apps** найдите ваш Web app
3. Удалите старый Web app (или создайте новый)
4. Создайте новый Web app:
   - Нажмите **"Add app"** → **Web (</>)**
   - Зарегистрируйте приложение
   - Скопируйте новую конфигурацию
5. Обновите переменные окружения в Netlify новыми значениями
6. Перезапустите деплой

## Полезные ссылки

- [Firebase Console](https://console.firebase.google.com/project/prompt-6a4fd)
- [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials?project=prompt-6a4fd)
- [Netlify Dashboard](https://app.netlify.com/)





