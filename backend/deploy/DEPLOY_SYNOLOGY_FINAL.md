# 🚀 Финальная инструкция по деплою на Synology

## Быстрый старт

### Вариант 1: Полный автоматический деплой (рекомендуется)

```bash
cd backend
bash deploy/full_synology_deploy.sh
```

Этот скрипт выполнит все шаги автоматически:
1. Деплой кода на Synology
2. Проверка Node.js и PM2
3. Установка зависимостей
4. Сборка проекта
5. Настройка .env (создаст из env.example если нет)
6. Запуск через PM2
7. Проверка работы

### Вариант 2: Только обновление кода

```bash
cd backend
bash deploy/deploy_to_synology.sh
```

Затем вручную на Synology:
```bash
ssh admin@192.168.100.222
cd /volume1/Hotwell/Backends/shortsai-backend
npm install
npm run build
pm2 restart shortsai-backend
```

## Настройка SSH-ключей (если ещё не настроено)

Если SSH всё ещё требует пароль, выполните на Synology с правами root:

```bash
# Подключитесь к Synology
ssh admin@192.168.100.222

# Выполните с sudo (потребуется пароль admin)
sudo bash -c '
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)
sed -i "/^PubkeyAuthentication/d" /etc/ssh/sshd_config
sed -i "/^#PubkeyAuthentication/d" /etc/ssh/sshd_config
sed -i "/^AuthorizedKeysFile/d" /etc/ssh/sshd_config
sed -i "/^#AuthorizedKeysFile/d" /etc/ssh/sshd_config
echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
echo "AuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config
grep -E "PubkeyAuthentication|AuthorizedKeysFile" /etc/ssh/sshd_config
synoservice --restart sshd
'
```

## Полезные команды

### Обновление кода
```bash
cd backend
bash deploy/deploy_to_synology.sh
```

### Перезапуск backend
```bash
ssh admin@192.168.100.222 'pm2 restart shortsai-backend'
```

### Просмотр логов
```bash
ssh admin@192.168.100.222 'pm2 logs shortsai-backend'
```

### Статус PM2
```bash
ssh admin@192.168.100.222 'pm2 status'
```

### Проверка health endpoint
```bash
ssh admin@192.168.100.222 'curl http://localhost:8080/health'
```

### Редактирование .env
```bash
ssh admin@192.168.100.222 'nano /volume1/Hotwell/Backends/shortsai-backend/.env'
```

## Структура на Synology

```
/volume1/Hotwell/Backends/shortsai-backend/
├── src/              # Исходный код TypeScript
├── dist/             # Скомпилированный JavaScript
├── node_modules/     # Зависимости
├── .env              # Переменные окружения (НЕ в git)
├── package.json      # Зависимости проекта
├── tsconfig.json     # Конфигурация TypeScript
└── storage/          # Хранилище файлов
    └── videos/       # Видео файлы
```

## Настройка .env

После первого деплоя обязательно настройте `.env` на Synology:

```bash
ssh admin@192.168.100.222
cd /volume1/Hotwell/Backends/shortsai-backend
nano .env
```

Минимально необходимые переменные:
- `PORT=8080` - порт backend
- `BACKEND_URL=http://159.255.37.158:5000` - публичный URL (через VPS)
- `FIREBASE_SERVICE_ACCOUNT={...}` - JSON Service Account для Firebase
- `TELEGRAM_API_ID`, `TELEGRAM_API_HASH` - для Telegram
- `TELEGRAM_SESSION_SECRET` - секрет для шифрования сессий
- `STORAGE_ROOT=/volume1/Hotwell/Backends/shortsai-backend/storage/videos` - путь к хранилищу

## Устранение проблем

### Backend не запускается
```bash
ssh admin@192.168.100.222 'pm2 logs shortsai-backend --lines 50'
```

### Ошибки при сборке
```bash
ssh admin@192.168.100.222 'cd /volume1/Hotwell/Backends/shortsai-backend && npm run build'
```

### Проблемы с зависимостями
```bash
ssh admin@192.168.100.222 'cd /volume1/Hotwell/Backends/shortsai-backend && rm -rf node_modules && npm install'
```

### PM2 не сохраняет процессы после перезагрузки
```bash
ssh admin@192.168.100.222 'cd /volume1/Hotwell/Backends/shortsai-backend && pm2 save && pm2 startup'
# Выполните команду, которую выдаст pm2 startup (обычно с sudo)
```

## Автоматизация

Для автоматического деплоя при push в git, можно добавить в `.git/hooks/post-receive` или использовать GitHub Actions.

Текущий процесс:
1. Локально: `bash deploy/deploy_to_synology.sh` - обновляет код
2. На Synology автоматически через PM2 перезапускается (если настроен watch)

Или вручную:
```bash
ssh admin@192.168.100.222 'cd /volume1/Hotwell/Backends/shortsai-backend && pm2 restart shortsai-backend'
```




