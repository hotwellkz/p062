# Настройка публичного HTTPS API на VPS

Полный набор скриптов и документации для настройки публичного HTTPS API домена `api.hotwell.synology.me` на VPS с проксированием через VPN туннель на Synology DSM Backend.

## 📋 Описание

Решение позволяет:
- ✅ Публичный доступ к API через HTTPS (Let's Encrypt)
- ✅ Проксирование через VPN туннель (без открытия портов на домашнем роутере)
- ✅ Поддержка Range запросов для видео файлов (206 Partial Content)
- ✅ CORS заголовки для API
- ✅ Автоматическое обновление SSL сертификатов

## 🏗️ Архитектура

```
Интернет → VPS (159.255.37.158) → VPN → Synology (10.8.0.2:5001)
```

## 📁 Файлы в проекте

### Скрипты

1. **`setup_vps_api.sh`** - Основной скрипт автоматической настройки
   - Проверка VPN подключения
   - Определение порта backend
   - Установка и настройка Nginx
   - Настройка firewall
   - Подготовка к получению SSL сертификата

2. **`check_vps_status.sh`** - Скрипт проверки состояния системы
   - Проверка VPN подключения
   - Проверка доступности backend
   - Проверка статуса сервисов
   - Проверка DNS и SSL

### Конфигурационные файлы

3. **`nginx-api.hotwell.synology.me.conf`** - Готовая конфигурация Nginx
   - HTTP сервер для ACME challenge
   - HTTPS сервер с поддержкой Range
   - CORS заголовки
   - Оптимизация для больших файлов

### Документация

4. **`QUICK_START.md`** - Быстрый старт
   - Пошаговая инструкция
   - Команды проверки
   - Устранение проблем

5. **`VPS_SETUP_INSTRUCTIONS.md`** - Подробная инструкция
   - Детальное описание всех шагов
   - Расширенное устранение неполадок
   - Итоговая схема

6. **`README.md`** - Этот файл

## 🚀 Быстрый старт

1. **Загрузите файлы на VPS:**
   ```bash
   scp setup_vps_api.sh check_vps_status.sh root@159.255.37.158:/root/
   ```

2. **Выполните скрипт настройки:**
   ```bash
   ssh root@159.255.37.158
   chmod +x /root/setup_vps_api.sh
   /root/setup_vps_api.sh
   ```

3. **Настройте DNS:**
   - Создайте A-запись: `api.hotwell.synology.me` → `159.255.37.158`

4. **Получите SSL сертификат:**
   ```bash
   certbot --nginx -d api.hotwell.synology.me -m YOUR_EMAIL@example.com
   ```

5. **Проверьте работу:**
   ```bash
   curl -I https://api.hotwell.synology.me/health
   ```

Подробнее см. [QUICK_START.md](QUICK_START.md)

## 📝 Требования

- VPS с Ubuntu 24.04
- Доступ root/sudo
- Настроенный VPN туннель между VPS и Synology
- Backend на Synology слушает порт 5001 (или 5000)
- DNS доступ для создания A-записи

## 🔧 Основные компоненты

- **Nginx** - Reverse proxy с поддержкой Range запросов
- **Certbot** - Автоматическое получение и обновление SSL сертификатов
- **Let's Encrypt** - Бесплатные SSL сертификаты
- **UFW** - Firewall (если доступен)

## 🔍 Проверка работы

### Базовая проверка
```bash
/root/check_vps_status.sh
```

### Проверка endpoints
```bash
# Health check
curl -I https://api.hotwell.synology.me/health

# Range запрос (видео)
curl -r 0-1023 -I https://api.hotwell.synology.me/api/media/user/channel/file.mp4
```

### Проверка логов
```bash
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log
```

## 🛠️ Устранение неполадок

### ERR_CONNECTION_TIMED_OUT
- Проверьте firewall: `ufw status`
- Проверьте DNS: `dig +short api.hotwell.synology.me`
- Проверьте Nginx: `systemctl status nginx`

### 502 Bad Gateway
- Проверьте VPN: `ping -c 3 10.8.0.2`
- Проверьте backend: `curl -v http://10.8.0.2:5001/health`
- Проверьте порт в конфигурации Nginx

### Range запросы не работают
- Убедитесь, что `proxy_buffering off` в конфигурации
- Проверьте логи: `tail -50 /var/log/nginx/error.log`

Подробнее см. раздел "Устранение проблем" в [QUICK_START.md](QUICK_START.md)

## 📊 Итоговая схема

```
┌─────────────────────────────────────────────┐
│         Интернет (4G/любой)                │
│  https://api.hotwell.synology.me            │
└───────────────────┬─────────────────────────┘
                    │ HTTPS (443)
                    │ DNS: 159.255.37.158
                    ↓
┌─────────────────────────────────────────────┐
│  VPS Ubuntu 24.04                           │
│  IP: 159.255.37.158                         │
│  ┌───────────────────────────────────────┐ │
│  │  Nginx Reverse Proxy                  │ │
│  │  - SSL/TLS (Let's Encrypt)            │ │
│  │  - CORS headers                       │ │
│  │  - Range support (206)                │ │
│  └───────────────┬───────────────────────┘ │
│                  │ HTTP (5001)             │
│                  │ VPN tunnel              │
└──────────────────┼─────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────┐
│  VPN Network: 10.8.0.0/24                   │
│  ┌───────────────────────────────────────┐ │
│  │  VPS Gateway: 10.8.0.1                │ │
│  └───────────────┬───────────────────────┘ │
│                  │                          │
│                  ↓                          │
│  ┌───────────────────────────────────────┐ │
│  │  Synology Backend: 10.8.0.2:5001      │ │
│  │  - /health                            │ │
│  │  - /api/media/...                     │ │
│  └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

## 🔒 Безопасность

- ✅ Порт 80/443 открыт только на VPS
- ✅ Домашний роутер НЕ открывает порты
- ✅ Все соединения через VPN туннель
- ✅ Валидный SSL сертификат (Let's Encrypt)
- ⚠️ CORS настроен на "*" - ограничьте для production

## 📚 Дополнительная документация

- [QUICK_START.md](QUICK_START.md) - Быстрый старт и команды проверки
- [VPS_SETUP_INSTRUCTIONS.md](VPS_SETUP_INSTRUCTIONS.md) - Подробная инструкция

## 📞 Поддержка

При возникновении проблем:
1. Запустите `/root/check_vps_status.sh`
2. Проверьте логи: `tail -50 /var/log/nginx/error.log`
3. См. раздел "Устранение проблем" в документации

## 📄 Лицензия

Этот набор скриптов предоставляется "как есть" для использования в вашем проекте.
