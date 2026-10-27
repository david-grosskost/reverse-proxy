# Shared helpers for every make script. Sourced, never executed.
# shellcheck shell=bash
# Variables below are used by the scripts that source this file.
# shellcheck disable=SC2034

ENV_FILE=".env"
NETWORK="proxy"
LOCAL_DOMAIN="dev.localhost"
BOUNCER_KEY_FILE="secrets/crowdsec-bouncer.key"
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prints an error and exits.
#
# @param string $* Message
die () { printf '%s\n' "$*" >&2; exit 1; }

# Prints an indented message.
#
# @param string $* Message
info () { printf '  %s\n' "$*"; }

# Prints a command, then runs it.
#
# @param string $@ Command and arguments
run () {
  local arg shown=()
  for arg in "$@"; do
    case $arg in *[[:space:]]*) shown+=("\"$arg\"") ;; *) shown+=("$arg") ;; esac
  done
  printf '  \033[2m%s\033[0m\n' "${shown[*]}"
  "$@"
}

# Resolves APP_ENV: command-line parameter, then .env (optional), then local.
# The .env is read without being executed.
#
# @param string $1 Command name, for error messages
load_env () {
  local key value
  if [ -f "$ENV_FILE" ]; then
    while IFS='=' read -r key value || [ -n "$key" ]; do
      key="${key%$'\r'}"; value="${value%$'\r'}"
      [[ $key =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
      value="${value#\"}"; value="${value%\"}"
      [ -n "${!key:-}" ] || export "$key=$value"
    done < "$ENV_FILE"
  fi

  export APP_ENV="${APP_ENV:-local}"

  case "$APP_ENV" in
    local|prod) ;;
    *) die "$1 : APP_ENV doit valoir local ou prod (actuellement « ${APP_ENV:-} »)" ;;
  esac
}

# Exits unless APP_ENV matches.
#
# @param string $1 Command name, for error messages
# @param string $2 Required environment (local|prod)
require_app_env () {
  [ "$APP_ENV" = "$2" ] \
    || die "$1 : commande réservée à l'environnement $2 (APP_ENV=$APP_ENV)"
}

# Runs docker compose with the base file and the APP_ENV overlay.
#
# @param string $@ docker compose arguments
compose () {
  run docker compose -f compose.yaml -f "compose.$APP_ENV.yaml" "$@"
}

# Creates the shared network if missing.
#
# @return 0 if created, 1 if it already existed
ensure_network () {
  if docker network inspect "$NETWORK" >/dev/null 2>&1; then
    return 1
  fi
  run docker network create "$NETWORK"
}

# @return 0 if the Traefik container is running
proxy_running () {
  [ -n "$(docker compose -f compose.yaml -f "compose.$APP_ENV.yaml" \
          ps -q traefik 2>/dev/null)" ]
}

# Path of a tool: the project's pinned copy in .tools/bin/, else the system one.
#
# @param string $1 Tool name
# @return 1 if the tool is not found
tool () {
  if [ -x ".tools/bin/$1.exe" ]; then
    echo ".tools/bin/$1.exe"
  elif [ -x ".tools/bin/$1" ]; then
    echo ".tools/bin/$1"
  elif command -v "$1" >/dev/null; then
    echo "$1"
  else
    return 1
  fi
}
