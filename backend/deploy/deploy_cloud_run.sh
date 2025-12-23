#!/bin/bash
# Deploy ShortsAI Backend to Google Cloud Run
# Usage: bash deploy/deploy_cloud_run.sh

set -e

PROJECT_ID="prompt-6a4fd"
REGION="us-central1"
SERVICE_NAME="shortsai-backend"
JOB_NAME="shortsai-worker"
REPO_NAME="shortsai"
IMAGE_TAG="latest"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Deploying ShortsAI Backend to Cloud Run${NC}"
echo -e "${GREEN}============================================${NC}"

# Set project
echo -e "${YELLOW}Setting GCP project...${NC}"
gcloud config set project $PROJECT_ID

# Enable required APIs
echo -e "${YELLOW}Enabling required APIs...${NC}"
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  cloudscheduler.googleapis.com \
  secretmanager.googleapis.com \
  storage.googleapis.com \
  firestore.googleapis.com \
  --project=$PROJECT_ID

# Create Artifact Registry repository
echo -e "${YELLOW}Creating Artifact Registry repository...${NC}"
gcloud artifacts repositories create $REPO_NAME \
  --repository-format=docker \
  --location=$REGION \
  --description="ShortsAI Backend Docker images" \
  --project=$PROJECT_ID 2>/dev/null || echo "Repository already exists"

# Build and push image
IMAGE_URI="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$SERVICE_NAME:$IMAGE_TAG"
echo -e "${YELLOW}Building and pushing Docker image...${NC}"
gcloud builds submit \
  --tag $IMAGE_URI \
  --project=$PROJECT_ID \
  --region=$REGION

# Deploy Cloud Run Service (API)
echo -e "${YELLOW}Deploying Cloud Run Service (API)...${NC}"
gcloud run deploy $SERVICE_NAME \
  --image $IMAGE_URI \
  --platform managed \
  --region $REGION \
  --project $PROJECT_ID \
  --allow-unauthenticated \
  --port 8080 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --max-instances 10 \
  --min-instances 0 \
  --set-env-vars "NODE_ENV=production,ENABLE_CRON_SCHEDULER=false" \
  --set-secrets "FIREBASE_SERVICE_ACCOUNT=FIREBASE_SERVICE_ACCOUNT:latest,TELEGRAM_API_ID=TELEGRAM_API_ID:latest,TELEGRAM_API_HASH=TELEGRAM_API_HASH:latest,TELEGRAM_SESSION_ENCRYPTED=TELEGRAM_SESSION_ENCRYPTED:latest,TELEGRAM_SESSION_SECRET=TELEGRAM_SESSION_SECRET:latest,GOOGLE_DRIVE_CLIENT_EMAIL=GOOGLE_DRIVE_CLIENT_EMAIL:latest,GOOGLE_DRIVE_PRIVATE_KEY=GOOGLE_DRIVE_PRIVATE_KEY:latest,GOOGLE_CLIENT_ID=GOOGLE_CLIENT_ID:latest,GOOGLE_CLIENT_SECRET=GOOGLE_CLIENT_SECRET:latest,JWT_SECRET=JWT_SECRET:latest,CRON_SECRET=CRON_SECRET:latest" \
  --service-account "shortsai-backend@$PROJECT_ID.iam.gserviceaccount.com" || \
  echo -e "${YELLOW}Service account will be created automatically${NC}"

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --project $PROJECT_ID \
  --format="value(status.url)")

echo -e "${GREEN}Service deployed: $SERVICE_URL${NC}"

# Deploy Cloud Run Job (Worker)
echo -e "${YELLOW}Deploying Cloud Run Job (Worker)...${NC}"
gcloud run jobs deploy $JOB_NAME \
  --image $IMAGE_URI \
  --region $REGION \
  --project $PROJECT_ID \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --max-retries 1 \
  --task-timeout 300 \
  --command "npm" \
  --args "run,worker" \
  --set-env-vars "NODE_ENV=production" \
  --set-secrets "FIREBASE_SERVICE_ACCOUNT=FIREBASE_SERVICE_ACCOUNT:latest,TELEGRAM_API_ID=TELEGRAM_API_ID:latest,TELEGRAM_API_HASH=TELEGRAM_API_HASH:latest,TELEGRAM_SESSION_ENCRYPTED=TELEGRAM_SESSION_ENCRYPTED:latest,TELEGRAM_SESSION_SECRET=TELEGRAM_SESSION_SECRET:latest,GOOGLE_DRIVE_CLIENT_EMAIL=GOOGLE_DRIVE_CLIENT_EMAIL:latest,GOOGLE_DRIVE_PRIVATE_KEY=GOOGLE_DRIVE_PRIVATE_KEY:latest,GOOGLE_CLIENT_ID=GOOGLE_CLIENT_ID:latest,GOOGLE_CLIENT_SECRET=GOOGLE_CLIENT_SECRET:latest" \
  --service-account "shortsai-worker@$PROJECT_ID.iam.gserviceaccount.com" || \
  echo -e "${YELLOW}Service account will be created automatically${NC}"

# Create service accounts if needed
echo -e "${YELLOW}Creating service accounts...${NC}"
gcloud iam service-accounts create shortsai-scheduler \
  --display-name="ShortsAI Scheduler" \
  --project=$PROJECT_ID 2>/dev/null || echo "Service account already exists"

# Grant permissions
echo -e "${YELLOW}Granting permissions...${NC}"
gcloud run jobs add-iam-policy-binding $JOB_NAME \
  --region=$REGION \
  --member="serviceAccount:shortsai-scheduler@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.invoker" \
  --project=$PROJECT_ID

# Create Cloud Scheduler job
echo -e "${YELLOW}Creating Cloud Scheduler job...${NC}"
JOB_URI="https://$REGION-run.googleapis.com/v2/projects/$PROJECT_ID/locations/$REGION/jobs/$JOB_NAME:run"
gcloud scheduler jobs create http $JOB_NAME-scheduler \
  --location $REGION \
  --project $PROJECT_ID \
  --schedule "* * * * *" \
  --uri "$JOB_URI" \
  --http-method POST \
  --oauth-service-account-email "shortsai-scheduler@$PROJECT_ID.iam.gserviceaccount.com" \
  --time-zone "UTC" \
  --attempt-deadline 300s 2>/dev/null || \
  gcloud scheduler jobs update http $JOB_NAME-scheduler \
    --location $REGION \
    --project $PROJECT_ID \
    --schedule "* * * * *" \
    --uri "$JOB_URI" \
    --http-method POST \
    --oauth-service-account-email "shortsai-scheduler@$PROJECT_ID.iam.gserviceaccount.com" \
    --time-zone "UTC" \
    --attempt-deadline 300s

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Deployment completed!${NC}"
echo -e "${GREEN}============================================${NC}"
echo -e "${YELLOW}Service URL: $SERVICE_URL${NC}"
echo -e "${YELLOW}Health check: $SERVICE_URL/health${NC}"
echo -e "${YELLOW}View logs: gcloud run services logs read $SERVICE_NAME --region $REGION${NC}"
echo -e "${YELLOW}View job logs: gcloud run jobs executions list --job $JOB_NAME --region $REGION${NC}"

