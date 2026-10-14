#!/usr/bin/env bash
# Installs the mkcert certificate authority. Once per machine.
#
# @usage make cert@install
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env cert@install
require_app_env cert@install local

command -v mkcert >/dev/null \
  || die "cert@install : mkcert introuvable — https://github.com/FiloSottile/mkcert#installation"

run mkcert -install
