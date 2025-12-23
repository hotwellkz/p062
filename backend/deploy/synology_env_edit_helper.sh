#!/bin/bash

# ============================================
# Помощник для редактирования .env на Synology
# ============================================

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Загрузка конфигурации
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
else
    echo -e "${RED}❌ Ошибка: config.sh не найден${NC}"
    exit 1
fi

ENV_FILE="$SYNO_BACKEND_PATH/.env"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Помощник редактирования .env${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}❌ Файл .env не найден: $ENV_FILE${NC}"
    echo ""
    echo "Создайте .env из примера:"
    echo -e "${GREEN}  cp $SYNO_BACKEND_PATH/env.example $ENV_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}Путь к .env:${NC}"
echo "  $ENV_FILE"
echo ""

echo -e "${GREEN}Первые 50 строк .env:${NC}"
echo ""
head -50 "$ENV_FILE" | cat -n
echo ""

echo -e "${YELLOW}Команды для редактирования:${NC}"
echo ""

# Проверяем доступные редакторы
if command -v nano &> /dev/null; then
    echo -e "${GREEN}  nano $ENV_FILE${NC}"
elif command -v vi &> /dev/null; then
    echo -e "${GREEN}  vi $ENV_FILE${NC}"
elif command -f /usr/bin/vi &> /dev/null; then
    echo -e "${GREEN}  /usr/bin/vi $ENV_FILE${NC}"
else
    echo -e "${YELLOW}  Редакторы не найдены. Используйте:${NC}"
    echo -e "${GREEN}  cat > $ENV_FILE << 'EOF'${NC}"
    echo -e "${GREEN}  # вставьте содержимое${NC}"
    echo -e "${GREEN}  EOF${NC}"
fi

echo ""
echo -e "${YELLOW}Или скопируйте .env на ваш компьютер, отредактируйте и загрузите обратно:${NC}"
echo ""
echo -e "${GREEN}  # Скачать${NC}"
echo -e "  scp $SYNO_USER@$SYNO_HOST:$ENV_FILE .env.backup"
echo ""
echo -e "${GREEN}  # Отредактировать локально${NC}"
echo -e "  # ... отредактируйте .env.backup ..."
echo ""
echo -e "${GREEN}  # Загрузить обратно${NC}"
echo -e "  scp .env.backup $SYNO_USER@$SYNO_HOST:$ENV_FILE"
echo ""

echo -e "${BLUE}============================================${NC}"





