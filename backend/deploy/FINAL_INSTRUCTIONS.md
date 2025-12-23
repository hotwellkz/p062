# ✅ Итоговые инструкции по деплою

## 📋 Список созданных/изменённых файлов

### Обновлённые конфигурации:
1. `backend/deploy/config.sh` - обновлён под новый VPS (159.255.37.158)
2. `backend/vps/synology-port-forward.sh` - обновлён IP и порты (5000 для backend)
3. `backend/env.example` - обновлены примеры BACKEND_URL

### Скрипты деплоя:
4. `backend/deploy/full_deploy.sh` - главный скрипт автодеплоя
5. `backend/deploy/vps_setup.sh` - настройка VPS
6. `backend/deploy/synology_deploy.sh` - деплой на Synology
7. `backend/deploy/synology_env_edit_helper.sh` - помощник для .env

### Документация:
8. `backend/deploy/DEPLOY_README.md` - полная документация
9. `backend/deploy/QUICK_START.md` - быстрый старт
10. `backend/deploy/SETUP_NEW_VPS.md` - инструкция по настройке нового VPS
11. `backend/deploy/FINAL_INSTRUCTIONS.md` - этот файл

## 🚀 Команды для запуска

### ОДНА КОМАНДА для полного деплоя:

**Linux/macOS/Git Bash:**
```bash
cd backend/deploy
chmod +x *.sh
./full_deploy.sh
```

**Windows PowerShell:**
```powershell
cd backend\deploy
bash full_deploy.sh
```

**Или используйте готовые скрипты:**
```powershell
# PowerShell скрипт
.\deploy.ps1
```

```cmd
# Batch файл (можно запустить двойным кликом)
START_DEPLOY.bat
```

> **Примечание для Windows:** 
> - Если `bash` не найден, установите **Git for Windows** (включает Git Bash)
> - Или используйте готовые обёртки: `deploy.ps1` или `START_DEPLOY.bat`
> - Подробнее: `backend/deploy/WINDOWS_DEPLOY.md`

Скрипт автоматически:
1. ✅ Подключится к VPS (159.255.37.158) и настроит его
2. ✅ Настроит проброс портов (5000 → Synology:8080)
3. ✅ Подключится к Synology (192.168.100.222) и задеплоит backend
4. ✅ Обновит репозиторий, установит зависимости, скомпилирует TypeScript
5. ✅ Запустит через pm2 и проверит работоспособность

## 📝 Что ОБЯЗАТЕЛЬНО заполнить вручную

### 1. В `backend/deploy/config.sh`:

```bash
# Проверьте/измените:
export GITHUB_REPO_URL="https://github.com/hotwellkz/p041.git"  # ВАШ репозиторий!
```

### 2. В `.env` на Synology (после первого деплоя):

**Обязательные переменные:**

```env
# Backend настройки (автоматически настроятся, но можно изменить)
NODE_ENV=production
PORT=8080
STORAGE_ROOT=/volume1/shortsai/videos
BACKEND_URL=http://159.255.37.158:5000
# ИЛИ используйте домен:
# BACKEND_URL=http://vm3737624.firstbyte.club:5000

# Firebase (выберите ОДИН вариант):
# Вариант 1: Полный JSON
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"...",...}

# Вариант 2: Отдельные переменные
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# Telegram (обязательно!)
TELEGRAM_API_ID=your-api-id
TELEGRAM_API_HASH=your-api-hash
TELEGRAM_SESSION_SECRET=64-char-hex-string  # Сгенерируйте: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
SYNX_CHAT_ID=your-syntx-chat-id
```

## 🔧 Первый запуск (пошагово)

### Шаг 1: Настройте config.sh

```bash
cd backend/deploy
nano config.sh
```

Проверьте:
- `VPS_IP="159.255.37.158"` ✅
- `SYNO_HOST="192.168.100.222"` ✅
- `GITHUB_REPO_URL="https://github.com/hotwellkz/p041.git"` ⚠️ **ЗАПОЛНИТЕ!**

### Шаг 2: Проверьте SSH доступ

```bash
# VPS
ssh root@159.255.37.158
# Введите пароль, проверьте подключение

# Synology
ssh admin@192.168.100.222
# Введите пароль, проверьте подключение
```

### Шаг 3: Запустите деплой

```bash
cd backend/deploy
chmod +x *.sh
./full_deploy.sh
```

### Шаг 4: Настройте .env на Synology

После первого деплоя:

```bash
ssh admin@192.168.100.222
cd /volume1/shortsai/app/backend
bash deploy/synology_env_edit_helper.sh
# Или
nano .env
```

Заполните обязательные переменные (см. выше).

### Шаг 5: Перезапустите backend

```bash
ssh admin@192.168.100.222
cd /volume1/shortsai/app/backend
pm2 restart shortsai-backend
```

## ✅ Проверка работоспособности

```bash
# Health check
curl http://159.255.37.158:5000/health
# Должен вернуть: {"ok":true}

# Или через домен
curl http://vm3737624.firstbyte.club:5000/health
```

## 🔄 Обновление приложения

Просто запустите снова:

```bash
cd backend/deploy
./full_deploy.sh
```

## 📚 Дополнительная документация

- **Полная документация**: `backend/deploy/DEPLOY_README.md`
- **Быстрый старт**: `backend/deploy/QUICK_START.md`
- **Настройка нового VPS**: `backend/deploy/SETUP_NEW_VPS.md`

## 🆘 Если что-то не работает

1. **Проверьте логи на Synology:**
   ```bash
   ssh admin@192.168.100.222 'pm2 logs shortsai-backend --lines 50'
   ```

2. **Проверьте .env:**
   ```bash
   ssh admin@192.168.100.222 'cat /volume1/shortsai/app/backend/.env | grep -v "^#" | grep -v "^$"'
   ```

3. **Проверьте проброс портов на VPS:**
   ```bash
   ssh root@159.255.37.158 'iptables -t nat -L PREROUTING -n -v | grep 5000'
   ```

4. **Проверьте статус pm2:**
   ```bash
   ssh admin@192.168.100.222 'pm2 status'
   ```

---

## 🎯 Итого

**Одна команда для деплоя:**
```bash
cd backend/deploy && ./full_deploy.sh
```

**Что заполнить вручную:**
1. `GITHUB_REPO_URL` в `config.sh`
2. `.env` на Synology (Firebase, Telegram секреты)

**Готово! 🚀**

