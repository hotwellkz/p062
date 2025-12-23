# 🔧 Ручная установка PM2 на Synology

## Проблема

Установка `pm2` через `npm install -g pm2` зависает из-за проблем с сетью/DNS на Synology.

## Решение 1: Установка pm2 локально (рекомендуется)

```bash
# На Synology
cd /volume1/Backends/shortsai-backend

# Установите pm2 как локальную зависимость
npm install pm2 --save-dev

# Используйте локальный pm2
node_modules/.bin/pm2 start dist/index.js --name shortsai-backend
node_modules/.bin/pm2 save
node_modules/.bin/pm2 startup
```

## Решение 2: Использование npx

```bash
# На Synology
cd /volume1/Backends/shortsai-backend

# Используйте npx для запуска pm2
npx pm2 start dist/index.js --name shortsai-backend
npx pm2 save
npx pm2 startup
```

## Решение 3: Установка через Package Center

1. Откройте **Package Center** на Synology
2. Найдите **Node.js v20** (если не установлен)
3. Установите через веб-интерфейс

## Решение 4: Исправление DNS на Synology

Если проблема в DNS:

```bash
# На Synology (требуются права root)
sudo nano /etc/resolv.conf

# Добавьте:
nameserver 8.8.8.8
nameserver 8.8.4.4

# Сохраните и перезапустите сеть
sudo /etc/rc.network restart
```

## Решение 5: Использование альтернативного реестра npm

```bash
# На Synology
npm config set registry https://registry.npmmirror.com
npm install -g pm2
```

## После установки

Проверьте работу:

```bash
# Проверка версии
pm2 -v
# или
node_modules/.bin/pm2 -v

# Запуск backend
pm2 start dist/index.js --name shortsai-backend
# или
node_modules/.bin/pm2 start dist/index.js --name shortsai-backend

# Сохранение конфигурации
pm2 save
# или
node_modules/.bin/pm2 save

# Настройка автозапуска
pm2 startup
# Выполните команду, которую выдаст pm2 (обычно с sudo)
```

## Если установка всё ещё зависает

Прервите процесс (Ctrl+C) и выполните вручную:

```bash
# 1. Установите зависимости проекта
npm install

# 2. Соберите проект
npm run build

# 3. Установите pm2 локально
npm install pm2 --save-dev

# 4. Запустите через локальный pm2
node_modules/.bin/pm2 start dist/index.js --name shortsai-backend
node_modules/.bin/pm2 save
```




