#!/usr/bin/env bash
# Generates the local wildcard certificate for *.dev.localhost.
# One level below localhost: browsers reject a *.localhost wildcard.
#
# @usage make cert@create
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env cert@create
require_app_env cert@create local

mkcert="$(tool mkcert)" \
  || die "cert@create : mkcert introuvable — lancer « make cert@install »"

mkdir -p certs
run "$mkcert" -cert-file certs/local.pem -key-file certs/local-key.pem "*.$LOCAL_DOMAIN"

if proxy_running; then
  info "Le proxy tourne : « make app@restart » pour charger le nouveau certificat."
fi
