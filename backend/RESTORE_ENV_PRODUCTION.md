# Восстановление .env.production

## ⚠️ Проблема

Файл `.env.production` отсутствует на сервере, что приводит к:
- Отсутствию переменной `FRONTEND_ORIGIN`
- Неправильной работе CORS
- Отсутствию других важных переменных окружения

## Проверка

Выполните на сервере:

```bash
cd /volume1/docker/shortsai/backend

# Проверить существующие env файлы
ls -la .env*

# Проверить содержимое .env.production (если есть)
cat .env.production 2>&1 || echo "File not found"
```

## Решение: Восстановить .env.production

### Вариант 1: Если есть резервная копия

```bash
# Проверить резервные копии
ls -la .env.production* .env*.bak .env*.backup

# Восстановить из резервной копии
cp .env.production.bak .env.production
```

### Вариант 2: Создать новый файл

Создайте файл `.env.production` с минимальными необходимыми переменными:

```bash
cat > .env.production << 'EOF'
# Frontend Origin
FRONTEND_ORIGIN=https://shortsai.ru

# Node Environment
NODE_ENV=production
PORT=3000
HOST=0.0.0.0

# Storage
STORAGE_ROOT=/app/storage/videos

# Telegram
TELEGRAM_API_ID=23896635
TELEGRAM_API_HASH=f4d3ff7cce4d9b8bc6ea2388f32b5973
SYNX_CHAT_ID=@syntxaibot
TELEGRAM_SESSION_SECRET=fac61ac113cceee13495768b345b3ef1e0683459150839779447955ac1d481f6

# JWT and Cron
JWT_SECRET=dev_jwt_secret_129384712983471
CRON_SECRET=dev_cron_secret_982734987

# Firebase
FIREBASE_API_KEY=AIzaSyCtAg7fTGY7EsyEQf1WXl0ei7HUO5ls0sQ
FIREBASE_AUTH_DOMAIN=prompt-6a4fd.firebaseapp.com
FIREBASE_PROJECT_ID=prompt-6a4fd
FIREBASE_STORAGE_BUCKET=prompt-6a4fd.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=905027425668
FIREBASE_APP_ID=1:905027425668:web:38f58912370df2c2be39d1
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@prompt-6a4fd.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCjTIdSG3raK4Uc\nhtUFbtSiCQewrRpV8WxmUqJdZs6a9SfItbwwiT/g+RTDJgQsbC2llJHF7uY4F+Qa\nsQx4kAXwJlAzXes0ln2N3ccTdZxjwDlYUZUTcrkro5K9xXl5ke4qvD32F6+CJbVT\nSLrYcu84+UHcBxFAyf4TIsvaHow5bzkmsP/9Zd25OhBJEuEilbzIZsyKgidYAmhj\nDWTRwqqxlzc9X5O7gCoXVvqaPLg9HZPAmO4gtAm9s9OfkG2sG9aG1X2G8wManlsX\nRqwB/O2gQzIyV3SqYjnDswls8Uba3QC9hLgPuXrknXRPXfUVzUacRwcZPdA7Vs+F\nUJUa2smNAgMBAAECggEAEc+LAt2UbK9KeW4LVehcsL+jYxW+RZlrZU2l/+HyrtwG\nVtHbkL+ng/Ym2ZIP6nhyEhk+PQRtf7i7XF3rKksrGqJTJQcdXEL9trd1ux2czRRu\nLL/ZLqHYqHXSz3f2Y9gSzf5yE6FJtzw9prPMDUeb5+7nzAPJUfO2DohBC61BRhI6\n444+Y0rovktb3nwqbToeeAflJTRu5A8hZO5CbRsd0lUNHF5ha46VKljskXEdpt/7\nSUDppCO2CGImTaMigG7qC8qg2r/M4BT5w7r1r3vaYe4MkIzhZEW1e5NwOCgLHULS\nXhNUALKJoP+XAY2/4h/2N74HLRrwuEBW3/br/yn4UQKBgQDNO99iSywxCm5PPPkU\n/AMd1DMFKWRh2DFDA30mL/LQT+lJ5DYAoBLw7hyQnIQu2qIlkU8aoMqWrFhGGiYW\ndoeJ0hLfivrvZ6t673/L1l4BXwyMmGWODcQFIhWJ4UmF7QdMB36ancbV+ksz+l84\nRErAzcl7BiLg+3f4J88r1V/8dwKBgQDLsTBh5y8Sfs0b8weSOZs6Ktd6spKqZ/bF\nPunNoAmfvNTFCtGxsdij2qYJ7JzrqMNEmJM2mIDv/AF9xUGmlszMG5gwoUOWNdG3\nlqG4r+9dyyeD/HQx7HG7rS+gpwIIFLs3eO+MnIwh2hbxW0V0empMzQyOZdT1uZnS\noHxBXw1fGwKBgCVhr2l26cCw9rCmGXRSBrtLKFPbWzZbK3XaT9RBzYdV1tcnoxJw\nFaMeq8NHTug92GThV7gw61WQZK+4GZHj2wImalufM9+hUWGd9/gHvq2fQ2jkZTL/\nnOGWeLfZegvTxY16m/vLmyjkYwg/pVJZVghSM02eK4IxK4PetGR2g/o3AoGAKcmn\nGF66THwRDivUoM4Kp2tEm5po9mavvJWEl7e+YbP2npnynRbUUAE6UQzmwH312WvH\nv8qXoSQ9FhVSu59yUmlS1p8u43EVHinb8ay+Waqk57HyEI/mYU9NVxMMGqZOJjo8\nQseXBBbe4BMOc6/tgOYMLmZ7wxGZmhlshGjAsIMCgYAzjDPdAwj8C9MxpZCBR+nJ\nIHx16wQGFB3OqmhPh8J0PbTNTCEvr3UncszSvTuQXrZ9Ts8Nn6tQhC61e5JuivVT\nq2l+MZNcyhdtUsrWI5fGW/AxFG3awpd/bdkIN3R/wg41ByzjiDqbLCJorR0lNf9u\nc+GWkClVeBPgO0m8Cc/liA==\n-----END PRIVATE KEY-----\n
EOF
```

**Важно:** Замените значения на актуальные из вашей конфигурации!

### Вариант 3: Использовать .env как основу

Если есть файл `.env`, можно скопировать его:

```bash
# Скопировать .env в .env.production
cp .env .env.production

# Или создать символическую ссылку (не рекомендуется для production)
# ln -s .env .env.production
```

## После восстановления

```bash
# Проверить файл
cat .env.production | grep FRONTEND_ORIGIN

# Установить права
chmod 600 .env.production

# Перезапустить контейнер
sudo /usr/local/bin/docker compose down
sudo /usr/local/bin/docker compose up -d

# Проверить переменные в контейнере
sudo /usr/local/bin/docker compose exec backend sh -c 'env | grep FRONTEND_ORIGIN'
```

## Важно

- Файл `.env.production` должен содержать все необходимые переменные
- Убедитесь, что `FRONTEND_ORIGIN=https://shortsai.ru` установлен
- После восстановления перезапустите контейнер





