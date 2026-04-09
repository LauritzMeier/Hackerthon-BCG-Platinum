#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_app_env.sh"

HOST="${API_HOST:-127.0.0.1}"
PORT="${API_PORT:-8000}"

usage() {
  cat <<EOF
Usage: ./scripts/run_api.sh [--host HOST] [--port PORT]

Starts the FastAPI backend for the Longevity Compass app.

Examples:
  ./scripts/run_api.sh
  ./scripts/run_api.sh --host 0.0.0.0 --port 8000
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST="$2"
      shift 2
      ;;
    --port)
      PORT="$2"
      shift 2
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

[[ -x "$REPO_ROOT/.venv/bin/python" ]] || die "Missing virtualenv Python at $REPO_ROOT/.venv/bin/python"

log "Starting API on ${HOST}:${PORT}"
cd "$REPO_ROOT"
exec "$REPO_ROOT/.venv/bin/python" -m uvicorn longevity_mvp.api:app --reload --app-dir src --host "$HOST" --port "$PORT"
