# Обновление Nginx конфига на VPS

## Команды для выполнения на VPS

### 1. Создать backup

```bash
ssh root@159.255.37.158
sudo cp /etc/nginx/sites-available/api.shortsai.ru /etc/nginx/sites-available/api.shortsai.ru.backup
```

### 2. Загрузить новый конфиг

**Из PowerShell (локально):**
```powershell
Get-Content nginx-api-shortsai-fixed.conf | ssh root@159.255.37.158 "cat > /etc/nginx/sites-available/api.shortsai.ru"
```

**Или в SSH сессии на VPS:**
```bash
# Открыть файл для редактирования
sudo nano /etc/nginx/sites-available/api.shortsai.ru

# Вставить содержимое из nginx-api-shortsai-fixed.conf
# Сохранить (Ctrl+O, Enter, Ctrl+X)
```

### 3. Проверить и перезагрузить

```bash
# Проверить синтаксис
sudo nginx -t

# Перезагрузить
sudo systemctl reload nginx
```

## Что добавлено в конфиг

Диагностические заголовки в location /:
- `X-Edge-Server` - hostname VPS
- `X-Edge-Time` - время запроса
- `X-Upstream` - адрес upstream (10.9.0.2:3000)
- `X-Upstream-Status` - статус ответа от upstream
- `X-URI` - полный URI запроса
- `X-Method` - HTTP метод
- `X-Host` - Host заголовок

## Проверка после обновления

```bash
# С VPS
curl -i https://api.shortsai.ru/health

# Из PowerShell
curl.exe -i https://api.shortsai.ru/health
```

В Response Headers должны появиться диагностические заголовки.

