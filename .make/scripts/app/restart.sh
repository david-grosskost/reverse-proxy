#!/usr/bin/env bash
# Restarts the reverse proxy, e.g. after a certificate change.
#
# @usage make app@restart
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

"$SCRIPTS/app/stop.sh"
"$SCRIPTS/app/start.sh"
