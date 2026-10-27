#!/usr/bin/env bash
# Generates the key shared by Traefik and CrowdSec, if missing. Never
# overwrites it: CrowdSec registers the key on its first start, a new one
# would no longer match. app@install runs it.
#
# @usage make waf@key
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

if [ -f "$BOUNCER_KEY_FILE" ]; then
  info "Clé CrowdSec déjà présente ($BOUNCER_KEY_FILE)."
  exit 0
fi

mkdir -p "$(dirname "$BOUNCER_KEY_FILE")"
od -An -tx1 -N24 /dev/urandom | tr -d ' \n' > "$BOUNCER_KEY_FILE"
chmod 600 "$BOUNCER_KEY_FILE"
info "Clé CrowdSec générée ($BOUNCER_KEY_FILE)."
