#!/usr/bin/env bash

set -euo pipefail

RUN_PROJECT_ID="${1:-ai-hack26ham-435}"
FIREBASE_PROJECT_ID="${2:-ai-hack26ham-435}"
REGION="${3:-europe-west1}"
SERVICE_ACCOUNT_NAME="${4:-longevity-agent-sa}"

SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${RUN_PROJECT_ID}.iam.gserviceaccount.com"

echo "Bootstrapping agent infrastructure..."
echo "Run project: ${RUN_PROJECT_ID}"
echo "Firebase project: ${FIREBASE_PROJECT_ID}"
echo "Region: ${REGION}"
echo "Service account: ${SERVICE_ACCOUNT_EMAIL}"

gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  --project "${RUN_PROJECT_ID}"

gcloud services enable firestore.googleapis.com --project "${FIREBASE_PROJECT_ID}"

if ! gcloud iam service-accounts describe "${SERVICE_ACCOUNT_EMAIL}" --project "${RUN_PROJECT_ID}" >/dev/null 2>&1; then
  gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}" \
    --project "${RUN_PROJECT_ID}" \
    --display-name "Longevity Agent Runtime"
fi

# Allow the runtime identity to read/write Firestore in the Firebase project that owns the database.
gcloud projects add-iam-policy-binding "${FIREBASE_PROJECT_ID}" \
  --member "serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role "roles/datastore.user" \
  --condition=None

# Avoid consumer mismatch for Firestore API usage checks.
gcloud projects add-iam-policy-binding "${FIREBASE_PROJECT_ID}" \
  --member "serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role "roles/serviceusage.serviceUsageConsumer" \
  --condition=None

echo "Bootstrap complete."
echo "Use this service account for Cloud Run:"
echo "  ${SERVICE_ACCOUNT_EMAIL}"
