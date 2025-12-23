# Загрузка docker-compose.yml на сервер

## Проблема с scp

SCP не работает на Synology (subsystem request failed). Используйте один из методов ниже.

## Метод 1: Через SSH с heredoc (рекомендуется)

Выполните команду:

```bash
ssh -p 777 admin@hotwell.synology.me "cd /volume1/docker/shortsai/backend && cat > docker-compose.yml" << 'EOF'
version: '3.8'

services:
  backend:
    container_name: shorts-backend
    build:
      context: .
      dockerfile: Dockerfile
      args:
        BACKEND_PORT: ${BACKEND_PORT:-3000}
    ports:
      - "${BACKEND_PORT:-3000}:${BACKEND_PORT:-3000}"
    env_file:
      - .env.production
    restart: always
    environment:
      - PORT=${BACKEND_PORT:-3000}
      - NODE_ENV=production
    volumes:
      - ./storage:/app/storage
      - ./tmp:/app/tmp
EOF
```

## Метод 2: Через SSH с построчной записью

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend
cat > docker-compose.yml
```

Затем вставьте содержимое файла и нажмите `Ctrl+D` для завершения.

## Метод 3: Через vi/nano

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend
vi docker-compose.yml
# или
nano docker-compose.yml
```

Скопируйте содержимое из `backend/docker-compose.yml` и вставьте в редактор.

## После загрузки

Проверьте файл:

```bash
ssh -p 777 admin@hotwell.synology.me "cd /volume1/docker/shortsai/backend && cat docker-compose.yml | grep -A 2 volumes"
```

Должно показать:
```yaml
    volumes:
      - ./storage:/app/storage
      - ./tmp:/app/tmp
```

Затем перезапустите контейнер:

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend
sudo /usr/local/bin/docker compose down
sudo /usr/local/bin/docker compose up -d --build
```





