#!/usr/bin/env bash
# Prints the merged compose configuration, as Docker will run it.
#
# @usage make app@config
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@config

compose config
