#!/bin/bash
# Скрипт для запуска деплоя на Synology из уже клонированного репозитория
# Запустите на Synology: bash run_deploy_on_synology.sh

cd /volume1/shortsai/app/backend || exit 1

# Исправляем окончания строк для всех скриптов
find deploy -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true

# Запускаем деплой
bash deploy/synology_deploy.sh





