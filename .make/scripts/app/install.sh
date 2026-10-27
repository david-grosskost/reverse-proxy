#!/usr/bin/env bash
# Installs the reverse proxy from scratch. Safe to re-run: done steps are skipped.
# The environment is saved to .env, so later commands reuse it.
#
# @usage make app@install [APP_ENV=local|prod]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@install

if [ ! -f "$ENV_FILE" ]; then
  run cp .env.example "$ENV_FILE"
  sed "s/^APP_ENV=.*/APP_ENV=$APP_ENV/" "$ENV_FILE" > "$ENV_FILE.tmp"
  mv "$ENV_FILE.tmp" "$ENV_FILE"
  info "$ENV_FILE créé avec APP_ENV=$APP_ENV : les prochaines commandes l'utiliseront."
fi

if [ "$APP_ENV" = local ]; then
  "$SCRIPTS/git/hooks.sh"
  "$SCRIPTS/cert/install.sh"
  [ -f certs/local.pem ] || "$SCRIPTS/cert/create.sh"
else
  # No commits on a server: only post-merge is useful, gitleaks is not needed.
  run git config core.hooksPath .githooks
fi

"$SCRIPTS/app/start.sh"
