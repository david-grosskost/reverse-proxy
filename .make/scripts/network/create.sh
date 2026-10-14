#!/usr/bin/env bash
# Creates the shared "proxy" network if missing.
#
# @usage make network@create
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

if ensure_network; then
  info "Réseau « $NETWORK » créé."
else
  info "Réseau « $NETWORK » déjà présent, rien à faire."
fi
