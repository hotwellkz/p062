#!/bin/bash
# Остановка Cloud Run сервисов для работы только на Synology
# Usage: bash stop-cloud-run.sh

set -e

PROJECT_ID="prompt-6a4fd"
REGION="us-central1"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${YELLOW}============================================${NC}"
echo -e "${YELLOW}Остановка Cloud Run сервисов${NC}"
echo -e "${YELLOW}============================================${NC}"
echo -e "${CYAN}Проект: $PROJECT_ID${NC}"
echo -e "${CYAN}Регион: $REGION${NC}"
echo ""

# Проверка статуса проекта
echo -e "${YELLOW}🔍 Проверяю статус проекта...${NC}"
PROJECT_STATUS=$(gcloud projects describe $PROJECT_ID --format="value(lifecycleState)" 2>/dev/null || echo "")

if [ -z "$PROJECT_STATUS" ]; then
    echo -e "${RED}❌ Ошибка: Проект недоступен или приостановлен${NC}"
    echo -e "${YELLOW}Активируйте проект через Google Cloud Console${NC}"
    exit 1
fi

if [ "$PROJECT_STATUS" != "ACTIVE" ]; then
    echo -e "${YELLOW}⚠️  Проект не активен (статус: $PROJECT_STATUS)${NC}"
    echo -e "${YELLOW}Активируйте проект через Google Cloud Console${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Проект активен${NC}"
echo ""

# Список Cloud Run Services
echo -e "${YELLOW}📋 Поиск Cloud Run Services...${NC}"
SERVICES=$(gcloud run services list --project=$PROJECT_ID --region=$REGION --format="value(metadata.name)" 2>/dev/null || echo "")

if [ -n "$SERVICES" ]; then
    SERVICE_COUNT=$(echo "$SERVICES" | grep -c . || echo "0")
    echo -e "${CYAN}Найдено сервисов: $SERVICE_COUNT${NC}"
    
    echo "$SERVICES" | while read -r service; do
        if [ -z "$service" ]; then continue; fi
        
        echo ""
        echo -e "${YELLOW}🛑 Останавливаю сервис: $service${NC}"
        
        gcloud run services delete "$service" \
          --region=$REGION \
          --project=$PROJECT_ID \
          --quiet 2>/dev/null || true
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}  ✅ Сервис $service удален${NC}"
        else
            echo -e "${YELLOW}  ⚠️  Не удалось удалить $service (возможно, уже удален)${NC}"
        fi
    done
else
    echo -e "${CYAN}ℹ️  Cloud Run Services не найдены${NC}"
fi

echo ""

# Список Cloud Run Jobs
echo -e "${YELLOW}📋 Поиск Cloud Run Jobs...${NC}"
JOBS=$(gcloud run jobs list --project=$PROJECT_ID --region=$REGION --format="value(metadata.name)" 2>/dev/null || echo "")

if [ -n "$JOBS" ]; then
    JOB_COUNT=$(echo "$JOBS" | grep -c . || echo "0")
    echo -e "${CYAN}Найдено Jobs: $JOB_COUNT${NC}"
    
    echo "$JOBS" | while read -r job; do
        if [ -z "$job" ]; then continue; fi
        
        echo ""
        echo -e "${YELLOW}🛑 Удаляю Job: $job${NC}"
        
        gcloud run jobs delete "$job" \
          --region=$REGION \
          --project=$PROJECT_ID \
          --quiet 2>/dev/null || true
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}  ✅ Job $job удален${NC}"
        else
            echo -e "${YELLOW}  ⚠️  Не удалось удалить $job (возможно, уже удален)${NC}"
        fi
    done
else
    echo -e "${CYAN}ℹ️  Cloud Run Jobs не найдены${NC}"
fi

echo ""

# Остановка Cloud Scheduler Jobs
echo -e "${YELLOW}📋 Поиск Cloud Scheduler Jobs...${NC}"
SCHEDULERS=$(gcloud scheduler jobs list --project=$PROJECT_ID --location=$REGION --format="value(name)" 2>/dev/null || echo "")

if [ -n "$SCHEDULERS" ]; then
    SCHEDULER_COUNT=$(echo "$SCHEDULERS" | grep -c . || echo "0")
    echo -e "${CYAN}Найдено Scheduler Jobs: $SCHEDULER_COUNT${NC}"
    
    echo "$SCHEDULERS" | while read -r scheduler; do
        if [ -z "$scheduler" ]; then continue; fi
        
        # Извлекаем имя job из полного пути
        JOB_NAME=$(echo "$scheduler" | sed 's/.*\///')
        
        echo ""
        echo -e "${YELLOW}🛑 Удаляю Scheduler Job: $JOB_NAME${NC}"
        
        gcloud scheduler jobs delete "$JOB_NAME" \
          --location=$REGION \
          --project=$PROJECT_ID \
          --quiet 2>/dev/null || true
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}  ✅ Scheduler Job $JOB_NAME удален${NC}"
        else
            echo -e "${YELLOW}  ⚠️  Не удалось удалить $JOB_NAME (возможно, уже удален)${NC}"
        fi
    done
else
    echo -e "${CYAN}ℹ️  Cloud Scheduler Jobs не найдены${NC}"
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✅ Остановка Cloud Run завершена${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${CYAN}Теперь работает только backend на Synology:${NC}"
echo -e "${YELLOW}  https://api.hotwell.synology.me${NC}"
echo ""





