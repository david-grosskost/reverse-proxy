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
  [ -n "${ACME_DOMAIN:-}" ] \
    || die "app@start : ACME_DOMAIN absent du .env (ex. ACME_DOMAIN=example.com)"
  for file in "${OVH_KEY_FILES[@]}"; do
    [ -f "$file" ] \
      || die "app@start : clé OVH absente ($file) — lancer « make cert@ovh »"
  done
  # Traefik refuses an acme.json readable by others.
  mkdir -p certs
  touch certs/acme.json
  chmod 600 certs/acme.json
fi

[ -f "$BOUNCER_KEY_FILE" ] \
  || die "app@start : clé CrowdSec absente ($BOUNCER_KEY_FILE) — lancer « make waf@key »"

ensure_network || true

compose up -d

if [ "$APP_ENV" = local ]; then
  printf '\n  Tableau de bord : \033[36mhttps://traefik.%s\033[0m\n\n' "$LOCAL_DOMAIN"
fi
