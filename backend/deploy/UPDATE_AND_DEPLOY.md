# 🚀 Обновление репозитория и деплой через GitHub

## ✅ Простое решение

Вместо копирования файлов вручную, просто обновите репозиторий на Synology!

## 📋 Выполните на Synology:

```bash
# 1. Перейдите в корень репозитория
cd /volume1/shortsai/app

# 2. Обновите репозиторий из GitHub
git fetch origin main
git reset --hard origin/main

# 3. Перейдите в backend
cd backend

# 4. Проверьте, что папка deploy появилась
ls -la deploy/

# 5. Настройте PATH для Node.js
export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"

# 6. Исправьте окончания строк для скриптов
find deploy -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true

# 7. Запустите деплой
bash deploy/synology_deploy.sh
```

## 🔄 Или одной командой:

```bash
cd /volume1/shortsai/app && git fetch origin main && git reset --hard origin/main && cd backend && export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH" && find deploy -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null && bash deploy/synology_deploy.sh
```

## ✅ После обновления

Папка `deploy` появится автоматически, так как она уже есть в репозитории на GitHub: https://github.com/hotwellkz/p041.git

---

**Выполните команды выше на Synology! 🚀**





