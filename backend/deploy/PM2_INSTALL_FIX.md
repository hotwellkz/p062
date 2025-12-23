# ⏳ Установка pm2 - что делать если зависло

## Проблема

Скрипт завис на установке pm2 (`npm install -g pm2`).

## ✅ Это может быть нормально

Установка pm2 глобально может занять **2-5 минут**, особенно если:
- Медленное интернет-соединение
- npm кэш пустой
- Устанавливается много зависимостей

## 🔍 Что проверить

### 1. Подождите еще 2-3 минуты

Установка pm2 может занять время. Подождите.

### 2. Если действительно зависло

**Нажмите `Ctrl+C` чтобы прервать, затем:**

```bash
# Проверьте, установлен ли pm2
which pm2
pm2 -v

# Если pm2 уже установлен, продолжите деплой вручную:
cd /volume1/shortsai/app/backend
export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"

# Запустите backend через pm2
pm2 start dist/index.js --name shortsai-backend --node-args="--max-old-space-size=2048"
pm2 save
pm2 startup
```

### 3. Установите pm2 вручную

```bash
# На Synology
export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"
npm install -g pm2 --verbose

# Проверьте установку
pm2 -v
```

### 4. Если npm install -g не работает

**Попробуйте установить локально:**

```bash
cd /volume1/shortsai/app/backend
npm install pm2
./node_modules/.bin/pm2 start dist/index.js --name shortsai-backend
```

## 🚀 Продолжение деплоя вручную

**Если pm2 установлен, выполните:**

```bash
cd /volume1/shortsai/app/backend
export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"

# Определите путь к pm2
PM2_CMD="pm2"
if ! command -v pm2 &> /dev/null; then
    if [ -f "/volume1/@appstore/Node.js_v20/usr/local/bin/pm2" ]; then
        PM2_CMD="/volume1/@appstore/Node.js_v20/usr/local/bin/pm2"
    elif [ -f "./node_modules/.bin/pm2" ]; then
        PM2_CMD="./node_modules/.bin/pm2"
    fi
fi

# Остановите старый процесс (если есть)
$PM2_CMD stop shortsai-backend 2>/dev/null || true
$PM2_CMD delete shortsai-backend 2>/dev/null || true

# Запустите backend
mkdir -p /volume1/shortsai/logs
$PM2_CMD start dist/index.js \
    --name shortsai-backend \
    --node-args="--max-old-space-size=2048" \
    --log-date-format="YYYY-MM-DD HH:mm:ss Z" \
    --merge-logs \
    --log /volume1/shortsai/logs/backend.log

# Сохраните конфигурацию
$PM2_CMD save

# Настройте автозапуск
$PM2_CMD startup

# Проверьте статус
$PM2_CMD status

# Проверьте health endpoint
sleep 5
curl http://127.0.0.1:8080/health
```

---

**Подождите еще 2-3 минуты. Если не помогло - выполните команды выше вручную! 🚀**





