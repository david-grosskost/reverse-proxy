#!/usr/bin/env bash
# Sends a typical attack (a request for /.env) and checks that the WAF
# blocks it with a 403. Needs a site served by the proxy.
#
# @usage make waf@test [SITE=monsite.david-grosskost.fr]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env waf@test

host="${SITE:-}"
if [ -z "$host" ]; then
  [ "$APP_ENV" = local ] \
    || die "waf@test : préciser un site servi par le proxy — make waf@test SITE=monsite.david-grosskost.fr"
  host="traefik.$LOCAL_DOMAIN"
fi

code="$(curl -sk -o /dev/null -w '%{http_code}' "https://$host/.env")"
if [ "$code" = 403 ]; then
  info "WAF actif : https://$host/.env bloqué (403)."
else
  die "waf@test : https://$host/.env a répondu $code au lieu de 403 — voir « make app@logs SERVICE=crowdsec »"
fi
