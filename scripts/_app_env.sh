#!/usr/bin/env bash

set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly APP_DIR="$REPO_ROOT/apps/longevity_compass"
readonly FIREBASE_OPTIONS_FILE="$APP_DIR/lib/firebase_options.dart"
readonly LOCAL_ENV_FILE="${LOCAL_ENV_FILE:-$REPO_ROOT/.env.local}"
readonly LOCAL_ENV_EXAMPLE_FILE="$REPO_ROOT/.env.example"

load_local_env() {
  if [[ -f "$LOCAL_ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$LOCAL_ENV_FILE"
    set +a
  fi
}

load_local_env

readonly DEFAULT_ANDROID_EMULATOR_ID="${ANDROID_EMULATOR_ID:-${DEFAULT_ANDROID_EMULATOR_ID:-Pixel_8_API_36}}"
readonly DEFAULT_IOS_EMULATOR_ID="${IOS_SIMULATOR_ID:-${DEFAULT_IOS_EMULATOR_ID:-apple_ios_simulator}}"
readonly DEFAULT_ANDROID_DEVICE_ID="${ANDROID_DEVICE_ID:-${DEFAULT_ANDROID_DEVICE_ID:-RFCW90RPXXV}}"
readonly PUB_CACHE_BIN="${PUB_CACHE_BIN:-$HOME/.pub-cache/bin}"
readonly NPM_GLOBAL_BIN="${NPM_GLOBAL_BIN:-$HOME/.npm-global/bin}"
readonly ANDROID_SDK_ROOT_DIR="${ANDROID_SDK_ROOT:-/opt/homebrew/share/android-commandlinetools}"
readonly ANDROID_PLATFORM_TOOLS_DIR="${ANDROID_PLATFORM_TOOLS_DIR:-$ANDROID_SDK_ROOT_DIR/platform-tools}"
readonly ANDROID_EMULATOR_DIR="${ANDROID_EMULATOR_DIR:-$ANDROID_SDK_ROOT_DIR/emulator}"

prepend_path_if_dir() {
  if [[ -d "$1" ]]; then
    PATH="$1:$PATH"
  fi
}

prepend_path_if_dir "$PUB_CACHE_BIN"
prepend_path_if_dir "$NPM_GLOBAL_BIN"
prepend_path_if_dir "$ANDROID_PLATFORM_TOOLS_DIR"
prepend_path_if_dir "$ANDROID_EMULATOR_DIR"
export PATH

if [[ -d "$ANDROID_SDK_ROOT_DIR" ]]; then
  export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_SDK_ROOT_DIR}"
  export ANDROID_HOME="${ANDROID_HOME:-$ANDROID_SDK_ROOT_DIR}"
fi

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'Warning: %s\n' "$*" >&2
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

run_in_app() {
  (
    cd "$APP_DIR"
    "$@"
  )
}

run_in_repo() {
  (
    cd "$REPO_ROOT"
    "$@"
  )
}

write_local_env_value() {
  local key="$1"
  local value="$2"
  local target_file="${3:-$LOCAL_ENV_FILE}"
  local temp_file

  mkdir -p "$(dirname "$target_file")"
  if [[ ! -f "$target_file" ]]; then
    cat > "$target_file" <<EOF
# Local development defaults for the Longevity Compass scripts.
# Copy values from $LOCAL_ENV_EXAMPLE_FILE or let setup scripts populate them.
EOF
  fi

  temp_file="$(mktemp "${target_file}.XXXXXX")"
  if grep -Eq "^[[:space:]]*${key}=" "$target_file"; then
    awk -v key="$key" -v value="$value" '
      $0 ~ "^[[:space:]]*" key "=" {
        print key "=" value
        updated = 1
        next
      }
      { print }
      END {
        if (!updated) {
          print key "=" value
        }
      }
    ' "$target_file" > "$temp_file"
  else
    cat "$target_file" > "$temp_file"
    printf '%s=%s\n' "$key" "$value" >> "$temp_file"
  fi

  mv "$temp_file" "$target_file"
}

resolve_flutterfire_cmd() {
  if command -v flutterfire >/dev/null 2>&1; then
    command -v flutterfire
    return
  fi

  if [[ -x "$HOME/.pub-cache/bin/flutterfire" ]]; then
    printf '%s\n' "$HOME/.pub-cache/bin/flutterfire"
    return
  fi

  die "FlutterFire CLI is not installed or not on PATH."
}

firebase_is_configured() {
  [[ -f "$FIREBASE_OPTIONS_FILE" ]] && \
    ! grep -q "Firebase has not been configured" "$FIREBASE_OPTIONS_FILE"
}

ensure_local_api_warning() {
  local api_base_url="${1%/}"
  if ! curl -fsS "${api_base_url}/health" >/dev/null 2>&1; then
    warn "Local API is not reachable at ${api_base_url}."
    warn "Start it with ./scripts/run_api.sh in another terminal."
  fi
}

pick_flutter_device_id() {
  local device_kind="$1"
  local preferred_id="${2:-}"
  local devices_json

  devices_json="$(run_in_app flutter devices --machine)"
  python3 - "$device_kind" "$preferred_id" <<'PY' <<< "$devices_json"
import json
import sys

device_kind = sys.argv[1]
preferred_id = sys.argv[2]

try:
    devices = json.load(sys.stdin)
except json.JSONDecodeError:
    devices = []

if preferred_id:
    for device in devices:
        if device.get("id") == preferred_id or device.get("name") == preferred_id:
            print(device.get("id", ""))
            raise SystemExit

def is_android(device):
    return str(device.get("targetPlatform", "")).startswith("android")

def is_ios(device):
    target = str(device.get("targetPlatform", ""))
    device_id = str(device.get("id", ""))
    name = str(device.get("name", ""))
    return "ios" in target or device_id == "ios" or "iphone" in name.lower() or "ipad" in name.lower()

for device in devices:
    if device_kind == "android-physical" and is_android(device) and not device.get("emulator", False):
        print(device.get("id", ""))
        raise SystemExit
    if device_kind == "android-emulator" and is_android(device) and device.get("emulator", False):
        print(device.get("id", ""))
        raise SystemExit
    if device_kind == "ios" and is_ios(device):
        print(device.get("id", ""))
        raise SystemExit
PY
}

wait_for_flutter_device() {
  local device_kind="$1"
  local preferred_id="${2:-}"
  local timeout_seconds="${3:-90}"
  local waited=0

  while (( waited < timeout_seconds )); do
    local device_id
    device_id="$(pick_flutter_device_id "$device_kind" "$preferred_id" || true)"
    if [[ -n "$device_id" ]]; then
      printf '%s\n' "$device_id"
      return 0
    fi
    sleep 3
    waited=$(( waited + 3 ))
  done

  return 1
}
