# ⚠️ ВАЖНО: Деплой запускается с ЛОКАЛЬНОГО компьютера!

## ❌ Неправильно (запуск на Synology):

```bash
# НЕ ДЕЛАЙТЕ ТАК:
ssh admin@192.168.100.222
cd /volume1/Hotwell/Backends/shortsai-backend
bash deploy/full_synology_deploy.sh  # ❌ Это не сработает!
```

## ✅ Правильно (запуск с локального компьютера):

### Вариант 1: Через Git Bash (рекомендуется)

```bash
# На вашем Windows компьютере
cd C:\Users\studo\Downloads\p039-master\p039-master\backend
bash deploy/full_synology_deploy.sh
```

### Вариант 2: Через batch файл

```powershell
# В PowerShell
cd C:\Users\studo\Downloads\p039-master\p039-master\backend\deploy
.\START_DEPLOY.bat
```

### Вариант 3: Если Git Bash не установлен

Используйте WSL или установите Git for Windows:
- Скачайте: https://git-scm.com/download/win
- Установите с опцией "Git Bash"

## Что делает скрипт

1. **С локального компьютера** копирует код на Synology
2. **Через SSH** подключается к Synology
3. Устанавливает зависимости
4. Собирает проект
5. Запускает через PM2

## Если нужно запустить что-то на Synology

Если вы уже на Synology и хотите только установить зависимости/запустить:

```bash
# На Synology
cd /volume1/Hotwell/Backends/shortsai-backend
npm install
npm run build
pm2 start dist/index.js --name shortsai-backend
pm2 save
```

Но для полного деплоя **всегда запускайте с локального компьютера!**




