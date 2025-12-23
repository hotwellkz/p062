# 📍 Пути для деплоя на Synology

## ⚠️ ВАЖНО: Откуда запускать скрипты

### ✅ ПРАВИЛЬНО: С локального компьютера

Скрипты для **копирования кода** должны запускаться с **локального компьютера**:

```bash
# На вашем Windows компьютере (Git Bash или терминал Cursor)
cd C:\Users\studo\Downloads\p039-master\p039-master\backend
bash deploy/COPY_CODE_TO_SYNOLOGY.sh
```

### ✅ ПРАВИЛЬНО: На Synology

Скрипты для **установки и запуска** должны запускаться **на Synology**:

```bash
# На Synology
cd /volume1/Backends/shortsai-backend
bash deploy/setup_on_synology.sh
```

## Пути на Synology

### Реальный путь (где находится код):

```
/volume1/Backends/shortsai-backend/
```

**НЕ** `/volume1/Hotwell/Backends/shortsai-backend` (этого пути не существует)

## Полный процесс деплоя

### Шаг 1: Копирование кода (с локального компьютера)

```bash
# На вашем компьютере
cd C:\Users\studo\Downloads\p039-master\p039-master\backend
bash deploy/COPY_CODE_TO_SYNOLOGY.sh
```

Введите пароль когда запросит: `6999LqJiQguX`

### Шаг 2: Установка и запуск (на Synology)

```bash
# На Synology
ssh admin@192.168.100.222
cd /volume1/Backends/shortsai-backend
bash deploy/setup_on_synology.sh
```

## Если вы уже на Synology

Если код уже скопирован и вы хотите только установить зависимости и запустить:

```bash
# На Synology
cd /volume1/Backends/shortsai-backend
bash deploy/setup_on_synology.sh
```

Или вручную:

```bash
cd /volume1/Backends/shortsai-backend
npm install pm2 --save-dev
npm install
npm run build
node_modules/.bin/pm2 start dist/index.js --name shortsai-backend
node_modules/.bin/pm2 save
```

## Исправление путей в скриптах

Если скрипт пытается создать `/volume1/Hotwell/Backends/shortsai-backend`, это неправильный путь.

Правильный путь: `/volume1/Backends/shortsai-backend`

Используйте переменную окружения для переопределения:

```bash
SYNO_BACKEND_DIR=/volume1/Backends/shortsai-backend bash deploy/COPY_CODE_TO_SYNOLOGY.sh
```




