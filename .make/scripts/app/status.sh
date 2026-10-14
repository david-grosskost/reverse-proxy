#!/usr/bin/env bash
# Shows the containers status.
#
# @usage make app@status
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@status

compose ps
