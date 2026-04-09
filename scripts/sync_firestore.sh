#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_app_env.sh"

PROJECT_ID="${FIREBASE_PROJECT_ID:-}"
DATABASE_ID="${FIRESTORE_DATABASE_ID:-}"
EXTRA_ARGS=()

usage() {
  cat <<EOF
Usage: ./scripts/sync_firestore.sh --project PROJECT_ID [options]

Publishes patient summaries and experience snapshots from the local warehouse
into Firestore collections used by the Flutter app.

Examples:
  ./scripts/sync_firestore.sh --project my-firebase-project
  ./scripts/sync_firestore.sh --project my-firebase-project --database my-firestore-db
  ./scripts/sync_firestore.sh --project my-firebase-project --limit 50
  ./scripts/sync_firestore.sh --project my-firebase-project --patient-id PT0001
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_ID="$2"
      shift 2
      ;;
    --database)
      DATABASE_ID="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

[[ -n "$PROJECT_ID" ]] || die "Firebase project id is required."
[[ -x "$REPO_ROOT/.venv/bin/python" ]] || die "Missing virtualenv Python at $REPO_ROOT/.venv/bin/python"

if ! gcloud auth application-default print-access-token >/dev/null 2>&1; then
  warn "Application Default Credentials are not configured."
  warn "Run 'gcloud auth application-default login' or pass --credentials <service-account.json>."
fi

cd "$REPO_ROOT"
CMD=(
  "$REPO_ROOT/.venv/bin/python"
  scripts/sync_firestore.py
  --project "$PROJECT_ID"
)

if [[ -n "$DATABASE_ID" ]]; then
  CMD+=(--database "$DATABASE_ID")
fi

if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  CMD+=("${EXTRA_ARGS[@]}")
fi

exec "${CMD[@]}"
