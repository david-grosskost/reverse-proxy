#!/usr/bin/env bash
# Enables the versioned Git hooks of .githooks/ (scripts and commit messages checks).
# Once per clone; app@install runs it in local.
#
# @usage make git@hooks
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

git rev-parse --git-dir >/dev/null 2>&1 \
  || die "git@hooks : ce dossier n'est pas un dépôt Git"

run git config core.hooksPath .githooks
info "Hooks Git activés : les scripts et les messages de commit sont vérifiés."
