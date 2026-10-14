#!/usr/bin/env bash
# Follows a service's logs, starting with the last 100 lines.
#
# @usage make app@logs [SERVICE=traefik]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@logs

compose logs -f --tail=100 "${SERVICE:-traefik}"
