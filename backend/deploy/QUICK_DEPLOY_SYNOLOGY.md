# 🚀 Быстрый деплой на Synology (вы уже подключены!)

## ✅ Что уже готово:

- ✅ Вы подключены к Synology (admin@Hotwell:~$)
- ✅ Репозиторий клонирован в `/volume1/shortsai/app/backend`
- ✅ VPS настроен и проброс портов работает

## 📋 Что нужно сделать:

### Шаг 1: Проверьте Node.js

**На Synology выполните:**

```bash
# Проверка Node.js
node -v
npm -v
```

**Если Node.js НЕ установлен:**

1. Откройте DSM: `https://192.168.100.222:5001`
2. Package Center → найдите "Node.js v20" → Install
3. Дождитесь установки
4. Проверьте снова: `node -v`

### Шаг 2: Запустите деплой

**На Synology выполните:**

```bash
# Перейдите в директорию backend
cd /volume1/shortsai/app/backend

# Исправьте окончания строк для скриптов
find deploy -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true

# Запустите деплой
bash deploy/synology_deploy.sh
```

**Или используйте готовый скрипт:**

```bash
# Скопируйте скрипт (если нужно)
cd /volume1/shortsai/app/backend
cat > /tmp/run_deploy.sh << 'EOF'
cd /volume1/shortsai/app/backend
find deploy -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true
bash deploy/synology_deploy.sh
EOF

chmod +x /tmp/run_deploy.sh
bash /tmp/run_deploy.sh
```

## 🔧 Если Node.js не установлен через Package Center

**Попробуйте найти Node.js в стандартных местах:**

```bash
# Проверка стандартных путей
ls -la /volume1/@appstore/Node.js_v20/usr/local/bin/node
ls -la /usr/local/bin/node
ls -la /opt/bin/node

# Если найден, добавьте в PATH
export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"
node -v
```

## ✅ После деплоя проверьте

**На VPS:**

```bash
curl http://10.8.0.2:8080/health
curl http://159.255.37.158:5000/health
```

Оба должны вернуть: `{"ok":true}`

---

**Готово! Запустите деплой прямо сейчас! 🚀**





