#!/usr/bin/env bash
# Asks for the OVH API keys used by the DNS challenge, and saves each one in
# secrets/ (rights 600), from where Traefik reads it as a Docker secret. The
# keys are typed without being shown, and never pass through a command line or
# the shell history. Keys already present are kept: delete their file to
# replace them. app@install runs it in prod.
#
# Create the keys on https://eu.api.ovh.com/createToken/ with only these rights:
#   POST   /domain/zone/<domain>/*
#   DELETE /domain/zone/<domain>/*
#
# @usage make cert@ovh
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env cert@ovh
require_app_env cert@ovh prod

labels=("Application Key" "Application Secret" "Consumer Key")
missing=0
for file in "${OVH_KEY_FILES[@]}"; do
  [ -f "$file" ] || missing=1
done

if [ "$missing" = 0 ]; then
  info "Clés OVH déjà présentes (secrets/ovh-*)."
  exit 0
fi

[ -t 0 ] || die "cert@ovh : clés OVH absentes, à saisir dans un terminal — lancer « make cert@ovh »"

info "Clés de l'API OVH, créées sur https://eu.api.ovh.com/createToken/"
info "(droits POST et DELETE sur /domain/zone/${ACME_DOMAIN:-<domaine>}/*)."
info "La saisie n'est pas affichée."

mkdir -p secrets
for i in "${!OVH_KEY_FILES[@]}"; do
  file="${OVH_KEY_FILES[$i]}"
  [ ! -f "$file" ] || continue
  value=""
  while [ -z "$value" ]; do
    read -rsp "  ${labels[$i]} : " value
    printf '\n'
  done
  # Created unreadable by others before the key is written into it.
  ( umask 077 && printf '%s' "$value" > "$file" )
  info "→ $file"
done

if proxy_running; then
  info "Le proxy tourne : « make app@restart » pour prendre en compte les clés."
fi
