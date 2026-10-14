#!/usr/bin/env bash
# Stops the reverse proxy. The shared network is kept.
#
# @usage make app@stop [APP_ENV=local|prod]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@stop

compose down
