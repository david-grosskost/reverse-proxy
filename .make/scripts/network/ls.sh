#!/usr/bin/env bash
# Lists the containers attached to the "proxy" network.
#
# @usage make network@ls
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

docker network inspect "$NETWORK" >/dev/null 2>&1 \
  || die "network@ls : réseau « $NETWORK » absent — lancer « make network@create »"

containers="$(docker network inspect "$NETWORK" \
  --format '{{range .Containers}}{{.Name}}{{"\n"}}{{end}}' | sed '/^$/d' | sort)"

if [ -z "$containers" ]; then
  info "Aucun conteneur sur « $NETWORK »."
else
  printf '%s\n' "$containers" | sed 's/^/  /'
fi
