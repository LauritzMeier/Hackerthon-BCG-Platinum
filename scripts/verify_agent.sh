#!/usr/bin/env bash

set -euo pipefail

SERVICE_URL="${1:-https://longevity-agent-102290354167.europe-west1.run.app}"
PATIENT_ID="${2:-PT0001}"
DEBUG_MODE_INPUT="${3:-${AGENT_VERIFY_DEBUG:-false}}"

case "${DEBUG_MODE_INPUT}" in
  1|true|TRUE|yes|YES|on|ON|debug|--debug)
    INCLUDE_DEBUG="true"
    ;;
  *)
    INCLUDE_DEBUG="false"
    ;;
esac

echo "Verifying agent service at: ${SERVICE_URL}"
echo "Patient id for chat checks: ${PATIENT_ID}"
echo "Debug mode: ${INCLUDE_DEBUG}"

echo
echo "1) Health check"
HEALTH_RESPONSE="$(curl -fsS "${SERVICE_URL}/health")"
echo "${HEALTH_RESPONSE}"

if [[ "${INCLUDE_DEBUG}" == "true" ]]; then
  echo
  echo "1b) Runtime debug"
  curl -fsS "${SERVICE_URL}/debug/runtime"

  echo
  echo
  echo "1c) Firestore debug"
  curl -fsS "${SERVICE_URL}/debug/firebase/${PATIENT_ID}"
fi

echo
echo "2) Batch chat check"
CHAT_RESPONSE="$(curl -fsS -X POST "${SERVICE_URL}/chat" \
  -H "Content-Type: application/json" \
  -d "{\"patient_id\":\"${PATIENT_ID}\",\"message\":\"Explain my top longevity focus this week.\",\"include_evidence_index\":false,\"include_debug\":${INCLUDE_DEBUG}}")"
echo "${CHAT_RESPONSE}"

echo
echo "3) Stream chat check (first lines)"
# We use timeout so the command exits even if stream remains open longer.
if command -v timeout >/dev/null 2>&1; then
  timeout 8s curl -N -sS -X POST "${SERVICE_URL}/chat/stream" \
    -H "Content-Type: application/json" \
    -d "{\"patient_id\":\"${PATIENT_ID}\",\"message\":\"How is my sleep pillar doing?\",\"include_evidence_index\":false,\"include_debug\":${INCLUDE_DEBUG}}" | sed -n '1,20p'
else
  curl -N -sS -X POST "${SERVICE_URL}/chat/stream" \
    -H "Content-Type: application/json" \
    -d "{\"patient_id\":\"${PATIENT_ID}\",\"message\":\"How is my sleep pillar doing?\",\"include_evidence_index\":false,\"include_debug\":${INCLUDE_DEBUG}}" | sed -n '1,20p'
fi

echo
echo "Verification completed."
