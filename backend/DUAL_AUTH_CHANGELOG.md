# Changelog: Dual-Auth Support (Firebase + Local JWT)

## Дата: 2025-12-21

## Изменения

### Добавлена поддержка dual-auth в `backend/src/middleware/auth.ts`

**Что изменилось:**
1. Добавлена функция `isFirebaseToken()` для определения типа токена:
   - Проверяет наличие `kid` в JWT header (характерно для Firebase)
   - Проверяет `iss` в payload (Firebase токены имеют `securetoken.google.com`)

2. Обновлен middleware `authRequired()`:
   - **Firebase ID Token** (основной метод): проверка через `firebase-admin verifyIdToken`
   - **Local JWT** (fallback): проверка через `jsonwebtoken.verify()` с `JWT_SECRET`

3. Для локального JWT:
   - Требуется `role: 'admin'` для доступа к `/api/telegram/*`
   - При успешной проверке создается `req.user` с `uid`, `email`, `role`

4. Добавлено подробное логирование:
   - Какой метод авторизации используется (firebase vs jwt)
   - Причины отказа в авторизации
   - Успешная авторизация с указанием метода

### Зависимости

- `jsonwebtoken` уже установлен (v9.0.2)
- `@types/jsonwebtoken` уже установлен (v9.0.7)
- Никаких новых зависимостей не требуется

### Обратная совместимость

✅ **Полностью сохранена:**
- Firebase ID Token продолжает работать как основной метод
- Локальный JWT используется только как fallback
- Существующие запросы с Firebase токенами работают без изменений

### Переменные окружения

- `JWT_SECRET` - должен быть установлен для работы локального JWT (уже есть в `.env.production`)

### Тестирование

См. `TEST_DUAL_AUTH.md` для команд тестирования.

### Деплой

1. Обновить код на Synology
2. Пересобрать контейнер: `docker compose build --no-cache`
3. Перезапустить: `docker compose up -d`
4. Проверить логи: `docker logs shorts-backend --tail 50`

