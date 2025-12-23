#!/bin/bash
# Восстановление проекта prompt-6a4fd в Cloud Run
# Usage: bash restore-cloud-run.sh

set -e

PROJECT_ID="prompt-6a4fd"
REGION="us-central1"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Восстановление проекта $PROJECT_ID в Cloud Run${NC}"
echo -e "${GREEN}============================================${NC}"

# Проверка gcloud CLI
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ Ошибка: gcloud CLI не установлен${NC}"
    echo "Установите: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Установка проекта
echo -e "${YELLOW}📦 Устанавливаю проект: $PROJECT_ID${NC}"
gcloud config set project $PROJECT_ID

# Проверка биллинга
echo -e "${YELLOW}💳 Проверяю биллинг...${NC}"
BILLING_ACCOUNT=$(gcloud billing projects describe $PROJECT_ID --format="value(billingAccountName)" 2>/dev/null || echo "")

if [ -z "$BILLING_ACCOUNT" ] || [ "$BILLING_ACCOUNT" = "" ]; then
    echo -e "${RED}❌ Биллинг не привязан!${NC}"
    echo -e "${YELLOW}Доступные billing accounts:${NC}"
    gcloud billing accounts list --format="table(name,displayName)"
    echo ""
    echo -e "${YELLOW}Привяжите биллинг командой:${NC}"
    echo "gcloud billing projects link $PROJECT_ID --billing-account=BILLING_ACCOUNT_ID"
    echo ""
    read -p "Введите BILLING_ACCOUNT_ID (или нажмите Enter для пропуска): " BILLING_ID
    if [ -n "$BILLING_ID" ]; then
        gcloud billing projects link $PROJECT_ID --billing-account=$BILLING_ID
        echo -e "${GREEN}✅ Биллинг привязан${NC}"
    else
        echo -e "${RED}❌ Биллинг не привязан. Продолжение невозможно.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Биллинг привязан: $BILLING_ACCOUNT${NC}"
fi

# Включение API
echo -e "${YELLOW}🔧 Включаю необходимые API...${NC}"
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  cloudscheduler.googleapis.com \
  secretmanager.googleapis.com \
  storage.googleapis.com \
  firestore.googleapis.com \
  --project=$PROJECT_ID

echo -e "${GREEN}✅ API включены${NC}"

# Проверка Firestore
echo -e "${YELLOW}🔥 Проверяю Firestore...${NC}"
FIRESTORE_DB=$(gcloud firestore databases list --project=$PROJECT_ID --format="value(name)" 2>/dev/null | head -1 || echo "")

if [ -z "$FIRESTORE_DB" ]; then
    echo -e "${YELLOW}⚠️  Firestore база данных не найдена. Создаю...${NC}"
    gcloud firestore databases create \
      --location=$REGION \
      --type=firestore-native \
      --project=$PROJECT_ID || echo "База данных уже существует или ошибка создания"
else
    echo -e "${GREEN}✅ Firestore база данных найдена${NC}"
fi

# Создание секретов из .env файла
echo -e "${YELLOW}🔐 Настраиваю секреты...${NC}"

if [ ! -f .env ]; then
    echo -e "${RED}❌ Файл .env не найден!${NC}"
    echo "Создайте .env файл на основе env.example"
    exit 1
fi

# Функция для создания/обновления секрета
create_or_update_secret() {
    local SECRET_NAME=$1
    local SECRET_VALUE=$2
    
    if gcloud secrets describe $SECRET_NAME --project=$PROJECT_ID &>/dev/null; then
        echo -n "$SECRET_VALUE" | gcloud secrets versions add $SECRET_NAME \
          --data-file=- \
          --project=$PROJECT_ID
        echo -e "${GREEN}  ✅ Обновлен секрет: $SECRET_NAME${NC}"
    else
        echo -n "$SECRET_VALUE" | gcloud secrets create $SECRET_NAME \
          --data-file=- \
          --project=$PROJECT_ID
        echo -e "${GREEN}  ✅ Создан секрет: $SECRET_NAME${NC}"
    fi
}

# Читаем .env и создаем секреты
while IFS='=' read -r key value || [ -n "$key" ]; do
    # Пропускаем комментарии и пустые строки
    if [[ $key =~ ^#.*$ ]] || [ -z "$key" ]; then
        continue
    fi
    
    # Убираем пробелы
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    
    # Убираем кавычки если есть
    value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/')
    value=$(echo "$value" | sed "s/^'\(.*\)'$/\1/")
    
    # Обработка многострочных значений (FIREBASE_PRIVATE_KEY)
    if [[ $key == "FIREBASE_PRIVATE_KEY" ]]; then
        # Читаем до следующей переменной или конца файла
        full_value="$value"
        while IFS= read -r line; do
            if [[ $line =~ ^[A-Z_]+= ]]; then
                break
            fi
            full_value="$full_value\n$line"
        done
        value=$(echo -e "$full_value")
    fi
    
    # Создаем секреты только для важных переменных
    case $key in
        FIREBASE_PROJECT_ID|FIREBASE_CLIENT_EMAIL|FIREBASE_PRIVATE_KEY|FIREBASE_API_KEY|FIREBASE_AUTH_DOMAIN|FIREBASE_STORAGE_BUCKET|FIREBASE_MESSAGING_SENDER_ID|FIREBASE_APP_ID)
            # Эти переменные используем как env vars, не секреты
            ;;
        TELEGRAM_API_ID|TELEGRAM_API_HASH|TELEGRAM_SESSION_SECRET|TELEGRAM_SESSION_ENCRYPTED|SYNX_CHAT_ID)
            create_or_update_secret "$key" "$value"
            ;;
        JWT_SECRET|CRON_SECRET)
            create_or_update_secret "$key" "$value"
            ;;
        GOOGLE_DRIVE_CLIENT_EMAIL|GOOGLE_DRIVE_PRIVATE_KEY|GOOGLE_CLIENT_ID|GOOGLE_CLIENT_SECRET)
            create_or_update_secret "$key" "$value"
            ;;
        FIREBASE_SERVICE_ACCOUNT)
            # Если есть JSON service account, создаем секрет
            if [[ $value =~ ^\{.*\}$ ]]; then
                create_or_update_secret "$key" "$value"
            fi
            ;;
    esac
done < .env

echo -e "${GREEN}✅ Секреты настроены${NC}"

# Запуск деплоя
echo -e "${YELLOW}🚀 Запускаю деплой...${NC}"
cd "$(dirname "$0")"
bash deploy/deploy_cloud_run.sh

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Восстановление завершено!${NC}"
echo -e "${GREEN}============================================${NC}"





