#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_app_env.sh"

PROJECT_ID="${FIREBASE_PROJECT_ID:-}"
PLATFORMS="${FIREBASE_PLATFORMS:-android,ios,web}"
YES_FLAG="--yes"
SAVE_LOCAL_CONFIG="true"

usage() {
  cat <<EOF
Usage: ./scripts/setup_firebase.sh --project PROJECT_ID [options]

Configures Firebase for the Flutter app using FlutterFire.
By default, it also remembers the Firebase project locally in .env.local.

Examples:
  ./scripts/setup_firebase.sh --project my-firebase-project
  ./scripts/setup_firebase.sh --project my-firebase-project --platforms android,ios,web
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_ID="$2"
      shift 2
      ;;
    --platforms)
      PLATFORMS="$2"
      shift 2
      ;;
    --no-yes)
      YES_FLAG=""
      shift
      ;;
    --no-save)
      SAVE_LOCAL_CONFIG="false"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

if [[ -z "$PROJECT_ID" ]]; then
  read -r -p "Firebase project id: " PROJECT_ID
fi

[[ -n "$PROJECT_ID" ]] || die "Firebase project id is required."

require_cmd flutter
require_cmd firebase
require_cmd gcloud
FLUTTERFIRE_BIN="$(resolve_flutterfire_cmd)"

if ! firebase login:list >/dev/null 2>&1; then
  log "Firebase CLI is not authenticated yet. Opening login flow..."
  firebase login
fi

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
  warn "No active gcloud account detected."
  warn "If FlutterFire needs Google Cloud access, run 'gcloud auth login' after this script."
fi

log "Running FlutterFire configure for project ${PROJECT_ID}"
run_in_app flutter pub get
if [[ -n "$YES_FLAG" ]]; then
  run_in_app "$FLUTTERFIRE_BIN" configure --project="$PROJECT_ID" --platforms="$PLATFORMS" "$YES_FLAG"
else
  run_in_app "$FLUTTERFIRE_BIN" configure --project="$PROJECT_ID" --platforms="$PLATFORMS"
fi

if [[ "$SAVE_LOCAL_CONFIG" == "true" ]]; then
  write_local_env_value FIREBASE_PROJECT_ID "$PROJECT_ID"
  write_local_env_value APP_ENABLE_FIREBASE true
  log "Saved Firebase defaults to ${LOCAL_ENV_FILE}"
fi

log "Firebase setup completed for project ${PROJECT_ID}"
