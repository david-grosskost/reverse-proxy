#!/usr/bin/env bash
# Pulls the images and recreates the containers that changed.
#
# @usage make app@update
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@update

compose pull
ensure_network || true
compose up -d
