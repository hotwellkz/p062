# 🔧 Полная инструкция по установке и настройке PM2 на Synology

## Шаг 1: Прервите зависший процесс

```bash
# На Synology, если процесс ещё работает
# Нажмите Ctrl+C для прерывания
```

## Шаг 2: Установите pm2 локально

```bash
# На Synology
cd /volume1/Backends/shortsai-backend

# Установите pm2 локально (быстрее и надёжнее)
npm install pm2 --save-dev
```

Это установит pm2 в `node_modules/.bin/pm2` и добавит в `package.json` как devDependency.

## Шаг 3: Запустите backend через локальный pm2

```bash
# Остановите старый процесс (если есть)
node_modules/.bin/pm2 stop shortsai-backend 2>/dev/null || true
node_modules/.bin/pm2 delete shortsai-backend 2>/dev/null || true

# Запустите backend
node_modules/.bin/pm2 start dist/index.js --name shortsai-backend

# Проверьте статус
node_modules/.bin/pm2 status
```

## Шаг 4: Сохраните конфигурацию PM2

```bash
# Сохраните текущую конфигурацию процессов
node_modules/.bin/pm2 save
```

Это создаст файл `~/.pm2/dump.pm2` с конфигурацией процессов.

## Шаг 5: Настройте автозапуск PM2 при загрузке Synology

```bash
# Выполните команду для генерации скрипта автозапуска
node_modules/.bin/pm2 startup
```

**PM2 выдаст команду вида:**
```bash
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u admin --hp /var/services/homes/admin
```

**ВАЖНО:** Скопируйте и выполните **ИМЕННО ТУ КОМАНДУ**, которую выдаст pm2. Она будет содержать правильные пути для вашей системы.

### Пример выполнения:

```bash
# PM2 выдаст что-то вроде:
# sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u admin --hp /var/services/homes/admin

# Выполните эту команду (потребуется пароль admin)
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u admin --hp /var/services/homes/admin
```

**Если pm2 установлен локально**, команда может быть другой:
```bash
# PM2 может выдать:
sudo env PATH=$PATH:/volume1/Backends/shortsai-backend/node_modules/.bin /volume1/Backends/shortsai-backend/node_modules/.bin/pm2 startup systemd -u admin --hp /var/services/homes/admin
```

### Если команда не работает

На Synology иногда нужно использовать другой метод:

```bash
# Вариант 1: Создать systemd service вручную
sudo nano /etc/systemd/system/pm2-admin.service
```

Содержимое файла:
```ini
[Unit]
Description=PM2 process manager
Documentation=https://pm2.keymetrics.io/
After=network.target

[Service]
Type=forking
User=admin
LimitNOFILE=infinity
LimitNPROC=infinity
PIDFile=/var/services/homes/admin/.pm2/pm2.pid
Restart=on-failure

ExecStart=/volume1/Backends/shortsai-backend/node_modules/.bin/pm2 resurrect
ExecReload=/volume1/Backends/shortsai-backend/node_modules/.bin/pm2 reload all
ExecStop=/volume1/Backends/shortsai-backend/node_modules/.bin/pm2 kill

[Install]
WantedBy=multi-user.target
```

Затем:
```bash
sudo systemctl daemon-reload
sudo systemctl enable pm2-admin.service
sudo systemctl start pm2-admin.service
```

**Или вариант 2: Использовать Task Scheduler в DSM**

1. Откройте **Control Panel** → **Task Scheduler**
2. Создайте новую задачу: **Triggered Task** → **User-defined script**
3. Настройки:
   - **Task**: `PM2 Startup`
   - **User**: `admin`
   - **Event**: `Boot-up`
   - **Run command**: 
     ```bash
     cd /volume1/Backends/shortsai-backend && /volume1/Backends/shortsai-backend/node_modules/.bin/pm2 resurrect
     ```

## Шаг 6: Проверка работы

```bash
# Проверьте статус
node_modules/.bin/pm2 status

# Проверьте логи
node_modules/.bin/pm2 logs shortsai-backend

# Проверьте health endpoint
curl http://localhost:8080/health
```

## Полезные команды для работы с PM2

```bash
# Перезапуск
node_modules/.bin/pm2 restart shortsai-backend

# Остановка
node_modules/.bin/pm2 stop shortsai-backend

# Просмотр логов
node_modules/.bin/pm2 logs shortsai-backend

# Просмотр последних 50 строк логов
node_modules/.bin/pm2 logs shortsai-backend --lines 50

# Мониторинг
node_modules/.bin/pm2 monit

# Список процессов
node_modules/.bin/pm2 list

# Информация о процессе
node_modules/.bin/pm2 show shortsai-backend
```

## Создание алиаса для удобства

Чтобы не писать каждый раз `node_modules/.bin/pm2`, создайте алиас:

```bash
# Добавьте в ~/.bashrc или ~/.profile
echo 'alias pm2="/volume1/Backends/shortsai-backend/node_modules/.bin/pm2"' >> ~/.bashrc
source ~/.bashrc

# Теперь можно использовать просто:
pm2 status
pm2 restart shortsai-backend
```

## Если что-то пошло не так

### Проверка процессов PM2
```bash
node_modules/.bin/pm2 list
```

### Перезапуск всех процессов
```bash
node_modules/.bin/pm2 restart all
```

### Очистка и перезапуск
```bash
node_modules/.bin/pm2 delete all
node_modules/.bin/pm2 start dist/index.js --name shortsai-backend
node_modules/.bin/pm2 save
```

### Проверка автозапуска
```bash
# Перезагрузите Synology и проверьте, запустился ли backend
# После перезагрузки:
node_modules/.bin/pm2 list
```

---

**Готово!** Backend должен запускаться автоматически при загрузке Synology. 🎉




