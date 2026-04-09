#!/usr/bin/env bash

set -euo pipefail

RUN_PROJECT_ID="${1:-ai-hack26ham-435}"
FIREBASE_PROJECT_ID="${2:-ai-hack26ham-435}"
REGION="${3:-europe-west1}"
SERVICE_NAME="${4:-longevity-agent}"
SERVICE_ACCOUNT_NAME="${5:-longevity-agent-sa}"
FIRESTORE_DATABASE_ID="${6:-longevity-compass-firestore}"

SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${RUN_PROJECT_ID}.iam.gserviceaccount.com"

echo "Deploying longevity agent..."
echo "Run project: ${RUN_PROJECT_ID}"
echo "Firebase project: ${FIREBASE_PROJECT_ID}"
echo "Region: ${REGION}"
echo "Service: ${SERVICE_NAME}"
echo "Runtime service account: ${SERVICE_ACCOUNT_EMAIL}"
echo "Firestore database: ${FIRESTORE_DATABASE_ID}"

gcloud run deploy "${SERVICE_NAME}" \
  --project "${RUN_PROJECT_ID}" \
  --region "${REGION}" \
  --source . \
  --port 8080 \
  --service-account "${SERVICE_ACCOUNT_EMAIL}" \
  --allow-unauthenticated \
  --set-env-vars "FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID},FIRESTORE_DATABASE_ID=${FIRESTORE_DATABASE_ID}"
