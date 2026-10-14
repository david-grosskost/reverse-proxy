#!/usr/bin/env bash
# Enables the versioned Git hooks of .githooks/ (commit message check).
# Once per clone; app@install runs it in local.
#
# @usage make git@hooks
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

git rev-parse --git-dir >/dev/null 2>&1 \
  || die "git@hooks : ce dossier n'est pas un dépôt Git"

run git config core.hooksPath .githooks
info "Hooks Git activés : les messages de commit sont vérifiés."
