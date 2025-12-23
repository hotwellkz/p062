#!/bin/bash
# Скрипт для загрузки docker-compose.yml на сервер

ssh -p 777 admin@hotwell.synology.me "cd /volume1/docker/shortsai/backend && cat > docker-compose.yml" << 'EOF'
version: '3.8'

services:
  backend:
    # Имя контейнера
    container_name: shorts-backend
    
    # Сборка образа из текущей директории (где находится Dockerfile)
    build:
      context: .
      dockerfile: Dockerfile
      args:
        # Порт можно задать через build arg, но лучше через env
        BACKEND_PORT: ${BACKEND_PORT:-3000}
    
    # Проброс портов: хост:контейнер
    # Используем переменную окружения BACKEND_PORT (по умолчанию 3000)
    ports:
      - "${BACKEND_PORT:-3000}:${BACKEND_PORT:-3000}"
    
    # Переменные окружения из файла .env.production (если существует)
    # Если файла нет, можно использовать env_file: .env
    env_file:
      - .env.production
    
    # Автоматический перезапуск при падении контейнера
    restart: always
    
    # Передаем PORT в контейнер (приложение использует переменную PORT)
    environment:
      - PORT=${BACKEND_PORT:-3000}
      - NODE_ENV=production
    
    # Монтирование volumes для сохранения данных на хосте
    volumes:
      - ./storage:/app/storage
      - ./tmp:/app/tmp
EOF

echo "docker-compose.yml загружен на сервер"





