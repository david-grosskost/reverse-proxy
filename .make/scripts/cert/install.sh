#!/usr/bin/env bash
# Installs mkcert (pinned, in .tools/bin/) and its certificate authority, so
# that browsers trust the local certificates. Once per machine.
#
# @usage make cert@install
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env cert@install
require_app_env cert@install local

"$SCRIPTS/cert/mkcert.sh"
run "$(tool mkcert)" -install
