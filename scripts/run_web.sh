#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_app_env.sh"

DEVICE_ID="${WEB_DEVICE_ID:-chrome}"
API_BASE_URL="${APP_API_BASE_URL:-}"
AGENT_BASE_URL="${APP_AGENT_BASE_URL:-}"
ENABLE_FIREBASE="${APP_ENABLE_FIREBASE:-auto}"
FIREBASE_PROJECT_ID_FLAG="${FIREBASE_PROJECT_ID:-}"
FIRESTORE_DATABASE_ID="${FIRESTORE_DATABASE_ID:-}"
SHOULD_RUN_FIREBASE_SETUP="false"
DRY_RUN="false"
EXTRA_ARGS=()

usage() {
  cat <<EOF
Usage: ./scripts/run_web.sh [options] [-- flutter_run_args...]

Defaults:
  - Launches the Flutter web app on Chrome.
  - Uses Firestore-first mode when Firebase is enabled.
  - Enables Firebase automatically if the app is already configured.

Options:
  --device-id ID                Use a specific Flutter web device id.
  --api-base-url URL            Override the API base URL.
  --agent-base-url URL          Override the agent base URL used for /chat/stream.
  --firebase-project PROJECT    Configure Firebase before launch and enable it.
  --enable-firebase             Enable Firebase if config is present.
  --no-firebase                 Disable Firebase even if config is present.
  --dry-run                     Print the final flutter command without running it.
  --help                        Show this help text.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device-id)
      DEVICE_ID="$2"
      shift 2
      ;;
    --api-base-url)
      API_BASE_URL="$2"
      shift 2
      ;;
    --agent-base-url)
      AGENT_BASE_URL="$2"
      shift 2
      ;;
    --firebase-project)
      FIREBASE_PROJECT_ID_FLAG="$2"
      ENABLE_FIREBASE="true"
      SHOULD_RUN_FIREBASE_SETUP="true"
      shift 2
      ;;
    --enable-firebase)
      ENABLE_FIREBASE="true"
      shift
      ;;
    --no-firebase)
      ENABLE_FIREBASE="false"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      EXTRA_ARGS+=("$@")
      break
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

require_cmd flutter
require_cmd curl

if [[ -n "$FIREBASE_PROJECT_ID_FLAG" ]] && ! firebase_is_configured; then
  SHOULD_RUN_FIREBASE_SETUP="true"
fi

if [[ "$SHOULD_RUN_FIREBASE_SETUP" == "true" && "$DRY_RUN" != "true" ]]; then
  "$SCRIPT_DIR/setup_firebase.sh" --project "$FIREBASE_PROJECT_ID_FLAG"
fi

if [[ "$DRY_RUN" != "true" ]]; then
  run_in_app flutter pub get
fi

if [[ "$ENABLE_FIREBASE" == "auto" ]]; then
  if firebase_is_configured; then
    ENABLE_FIREBASE="true"
  else
    ENABLE_FIREBASE="false"
  fi
fi

if [[ "$ENABLE_FIREBASE" == "true" ]] && ! firebase_is_configured; then
  die "Firebase is enabled but the app is not configured yet. Run ./scripts/setup_firebase.sh --project <firebase-project-id> first."
fi

if [[ "$ENABLE_FIREBASE" != "true" ]]; then
  API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:8000}"
fi

if [[ "$DRY_RUN" != "true" && "$ENABLE_FIREBASE" != "true" ]]; then
  ensure_local_api_warning "$API_BASE_URL"
fi

CMD=(
  flutter
  run
  -d "$DEVICE_ID"
)

if [[ -n "$API_BASE_URL" ]]; then
  CMD+=(--dart-define=APP_API_BASE_URL="$API_BASE_URL")
fi

if [[ -n "$AGENT_BASE_URL" ]]; then
  CMD+=(--dart-define=APP_AGENT_BASE_URL="$AGENT_BASE_URL")
fi

if [[ "$ENABLE_FIREBASE" == "true" ]]; then
  CMD+=(--dart-define=APP_ENABLE_FIREBASE=true)
fi

if [[ -n "$FIRESTORE_DATABASE_ID" ]]; then
  CMD+=(--dart-define=APP_FIRESTORE_DATABASE_ID="$FIRESTORE_DATABASE_ID")
fi

if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  CMD+=("${EXTRA_ARGS[@]}")
fi

log "Target web device: ${DEVICE_ID}"
log "API base URL: ${API_BASE_URL:-"(not set)"}"
log "Agent base URL: ${AGENT_BASE_URL:-"(not set)"}"
log "Firebase enabled: ${ENABLE_FIREBASE}"
log "Firestore database: ${FIRESTORE_DATABASE_ID:-"(default)"}"

if [[ "$DRY_RUN" == "true" ]]; then
  printf 'cd %q &&' "$APP_DIR"
  printf ' %q' "${CMD[@]}"
  printf '\n'
  exit 0
fi

cd "$APP_DIR"
exec "${CMD[@]}"
