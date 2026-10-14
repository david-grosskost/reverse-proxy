#!/usr/bin/env bash
# Starts the reverse proxy, after checking what the environment needs.
#
# @usage make app@start [APP_ENV=local|prod]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@start

if [ "$APP_ENV" = local ]; then
  [ -f certs/local.pem ] && [ -f certs/local-key.pem ] \
    || die "app@start : certificat local absent — lancer « make cert@create »"
else
  # Traefik refuses an acme.json readable by others.
  mkdir -p certs
  touch certs/acme.json
  chmod 600 certs/acme.json
fi

ensure_network || true

compose up -d

if [ "$APP_ENV" = local ]; then
  printf '\n  Tableau de bord : \033[36mhttps://traefik.%s\033[0m\n\n' "$LOCAL_DOMAIN"
fi
