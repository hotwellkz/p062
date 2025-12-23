# 🚀 Деплой ShortsAI Backend на Synology

## Быстрый запуск

### Windows (рекомендуется через Git Bash):

```bash
cd C:\Users\studo\Downloads\p039-master\p039-master\backend
bash deploy/full_synology_deploy.sh
```

Или используйте batch файл:
```cmd
cd C:\Users\studo\Downloads\p039-master\p039-master\backend\deploy
START_DEPLOY.bat
```

## Что делает скрипт

1. ✅ Копирует код на Synology
2. ✅ Проверяет Node.js и PM2
3. ✅ Устанавливает зависимости
4. ✅ Собирает проект
5. ✅ Настраивает .env (создаёт из env.example если нет)
6. ✅ Запускает через PM2
7. ✅ Проверяет работу

## После деплоя

Настройте `.env` на Synology:
```bash
ssh admin@192.168.100.222 'nano /volume1/Hotwell/Backends/shortsai-backend/.env'
```

Заполните все необходимые переменные и перезапустите:
```bash
ssh admin@192.168.100.222 'pm2 restart shortsai-backend'
```

## Полезные команды

- **Обновить код**: `bash deploy/deploy_to_synology.sh`
- **Перезапустить**: `ssh admin@192.168.100.222 'pm2 restart shortsai-backend'`
- **Логи**: `ssh admin@192.168.100.222 'pm2 logs shortsai-backend'`
- **Статус**: `ssh admin@192.168.100.222 'pm2 status'`




