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
  for key in ACME_DOMAIN ACME_DNS_PROVIDER; do
    [ -n "${!key:-}" ] || die "app@start : $key absent du .env (voir .env.example)"
  done
  [ -f "$ACME_DNS_ENV" ] \
    || die "app@start : identifiants DNS absents ($ACME_DNS_ENV) — lancer « make cert@dns »"
  # CrowdSec data, kept in the project directory (compose.prod.yaml).
  mkdir -p data/crowdsec/config data/crowdsec/data
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
