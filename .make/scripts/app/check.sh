#!/usr/bin/env bash
# Checks that this machine can run the reverse proxy, and tells how to fix
# each missing prerequisite. All checks run, so every problem is shown at
# once. app@install runs it first, before changing anything.
#
# @usage make app@check [APP_ENV=local|prod]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@check

failed=0

# Prints a problem and how to fix it, and marks the check as failed.
#
# @param string $1 Problem
# @param string $2 Fix
problem () { printf 'app@check : %s\n  → %s\n' "$1" "$2" >&2; failed=1; }

command -v git >/dev/null \
  || problem "git introuvable" "installer Git : https://git-scm.com/downloads"

if [ "$APP_ENV" = local ]; then
  for cmd in curl sha256sum; do
    command -v "$cmd" >/dev/null \
      || problem "$cmd introuvable" "nécessaire pour télécharger mkcert et gitleaks"
  done
fi

if ! command -v docker >/dev/null; then
  problem "Docker introuvable" "installer Docker Desktop (Windows, macOS) ou Docker Engine (Linux)"
elif ! error="$(docker info 2>&1 >/dev/null)"; then
  if grep -qi 'permission denied' <<<"$error"; then
    problem "Docker refuse l'accès" "sudo usermod -aG docker \$USER, puis se déconnecter et se reconnecter"
  else
    problem "Docker ne répond pas" "démarrer Docker Desktop, ou « sudo systemctl start docker » sous Linux"
  fi
elif ! docker compose version >/dev/null 2>&1; then
  problem "docker compose introuvable" "installer Docker Compose v2 (inclus dans Docker Desktop)"
elif ! proxy_running; then
  # Listening sockets on 80 or 443 (ss on Linux, netstat on Windows and macOS).
  busy="$( { ss -ltn 2>/dev/null || netstat -an 2>/dev/null; } \
    | grep -E '[:.](80|443)[[:space:]]+[^[:space:]]*:(0|\*)([[:space:]]|$)' || true)"
  [ -z "$busy" ] \
    || problem "les ports 80 ou 443 sont déjà utilisés par un autre programme" \
      "le trouver avec « sudo ss -ltnp » (Linux) ou « netstat -ano | findstr \":80 :443\" » (Windows), puis l'arrêter"
fi

[ "$failed" = 0 ] && info "Prérequis OK ($APP_ENV)."
exit "$failed"
