# Проверка WireGuard и маршрутизации

## Проблема
502 Bad Gateway - Nginx не может подключиться к backend по 10.9.0.2:3000.

## Команды для диагностики

### На Synology (SSH сессия):

```bash
# 1. Проверить, слушает ли backend на порту 3000
sudo docker exec shorts-backend netstat -tlnp 2>/dev/null | grep 3000
# или
sudo docker exec shorts-backend ss -tlnp | grep 3000

# 2. Проверить доступность локально
curl -i http://localhost:3000/health
curl -i http://127.0.0.1:3000/health

# 3. Проверить переменную PORT
sudo docker exec shorts-backend printenv | grep PORT

# 4. Проверить WireGuard интерфейс
sudo wg show
ip addr show wg0

# 5. Проверить IP адрес на wg0
ip addr show wg0 | grep "inet "

# 6. Проверить маршруты
ip route | grep 10.9

# 7. Проверить iptables правила
sudo iptables -L -n | grep 3000
sudo iptables -L -n -t nat | grep 3000
```

### На VPS (159.255.37.158):

```bash
# 1. Проверить доступность через WireGuard
ping 10.9.0.2

# 2. Проверить порт 3000
curl -i http://10.9.0.2:3000/health
# или
telnet 10.9.0.2 3000

# 3. Проверить WireGuard на VPS
sudo wg show
ip addr show wg0

# 4. Проверить маршруты
ip route | grep 10.9
```

## Возможные проблемы и решения

### 1. Backend не слушает на порту 3000

**Решение:** Проверить переменную PORT в .env.production

```bash
cd /volume1/docker/shortsai/backend
cat .env.production | grep PORT
```

Если PORT не установлен или установлен другой порт - исправить.

### 2. WireGuard туннель не работает

**Решение:** Перезапустить WireGuard

```bash
# На Synology
sudo docker restart wireguard
# или
sudo systemctl restart wg-quick@wg0

# Проверить статус
sudo wg show
```

### 3. Неправильный IP адрес в Nginx

**Решение:** Проверить, что Nginx использует правильный IP

На VPS:
```bash
sudo cat /etc/nginx/sites-available/api.shortsai.ru | grep proxy_pass
```

Должно быть: `proxy_pass http://10.9.0.2:3000;`

### 4. Проблема с маршрутизацией

**Решение:** Добавить маршрут (если нужно)

На Synology:
```bash
sudo ip route add 10.9.0.1/32 dev wg0
```

На VPS:
```bash
sudo ip route add 10.9.0.2/32 dev wg0
```

### 5. Firewall блокирует порт 3000

**Решение:** Разрешить порт 3000

На Synology:
```bash
sudo iptables -A INPUT -p tcp --dport 3000 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --sport 3000 -j ACCEPT
```

## Быстрая проверка

Выполните на Synology:

```bash
# 1. Проверить логи backend
sudo docker logs shorts-backend --tail 50 | grep -E "listening|port|error|Error"

# 2. Проверить доступность локально
curl -v http://localhost:3000/health

# 3. Проверить WireGuard
sudo wg show
ping -c 3 10.9.0.1  # ping VPS через WireGuard
```

## Ожидаемый результат

После исправления:
- Backend должен быть доступен по `http://localhost:3000/health` на Synology
- Backend должен быть доступен по `http://10.9.0.2:3000/health` с VPS
- Nginx должен успешно проксировать запросы

