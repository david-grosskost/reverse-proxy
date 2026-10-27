#!/usr/bin/env bash
# Installs the reverse proxy from scratch. Safe to re-run: done steps are skipped.
# The environment is saved to .env, so later commands reuse it.
#
# @usage make app@install [APP_ENV=local|prod]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@install
"$SCRIPTS/app/check.sh"

# Every setting of .env.example given as a parameter is written to .env:
#   make app@install APP_ENV=prod ACME_EMAIL=me@example.com
if [ ! -f "$ENV_FILE" ]; then
  run cp .env.example "$ENV_FILE"
  while IFS='=' read -r key _; do
    [[ $key =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] && [ -n "${!key:-}" ] || continue
    awk -v k="$key" -v v="${!key}" 'index($0, k "=") == 1 { $0 = k "=" v } { print }' \
      "$ENV_FILE" > "$ENV_FILE.tmp"
    mv "$ENV_FILE.tmp" "$ENV_FILE"
  done < .env.example
  info "$ENV_FILE créé avec APP_ENV=$APP_ENV : les prochaines commandes l'utiliseront."
fi

"$SCRIPTS/waf/key.sh"

if [ "$APP_ENV" = local ]; then
  "$SCRIPTS/git/hooks.sh"
  "$SCRIPTS/cert/install.sh"
  [ -f certs/local.pem ] || "$SCRIPTS/cert/create.sh"
else
  # No commits on a server: only post-merge is useful, gitleaks is not needed.
  run git config core.hooksPath .githooks
fi

"$SCRIPTS/app/start.sh"
