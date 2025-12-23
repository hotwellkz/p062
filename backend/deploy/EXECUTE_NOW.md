# 🚀 Выполните это ПРЯМО СЕЙЧАС на Synology

## Вы уже на Synology (admin@Hotwell:~$)

### Выполните эти команды:

```bash
# 1. Перейдите в директорию backend
cd /volume1/shortsai/app/backend

# 2. Проверьте структуру
ls -la
ls -la deploy/

# 3. Если папка deploy существует, запустите:
find deploy -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true
export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"
bash deploy/synology_deploy.sh

# 4. Если папки deploy НЕТ, создайте её и скопируйте скрипты:
mkdir -p deploy
# Затем скопируйте скрипты с вашего компьютера или используйте git pull
```

## Или используйте готовый скрипт

**Создайте скрипт прямо на Synology:**

```bash
cd /volume1/shortsai/app/backend

cat > /tmp/run_deploy.sh << 'EOFSCRIPT'
cd /volume1/shortsai/app/backend
export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"
if [ -d "deploy" ]; then
    find deploy -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true
    bash deploy/synology_deploy.sh
else
    echo "ERROR: deploy directory not found"
    echo "Run: git pull to update repository"
fi
EOFSCRIPT

chmod +x /tmp/run_deploy.sh
bash /tmp/run_deploy.sh
```

## Если папка deploy отсутствует

**Обновите репозиторий:**

```bash
cd /volume1/shortsai/app
git pull origin main
cd backend
```

---

**Выполните команды выше на Synology! 🚀**





