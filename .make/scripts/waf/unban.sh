#!/usr/bin/env bash
# Unblocks an IP, e.g. your own after a false positive.
#
# @usage make waf@unban IP=1.2.3.4
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env waf@unban

[ -n "${IP:-}" ] || die "waf@unban : préciser l'adresse — make waf@unban IP=1.2.3.4"

compose exec -T crowdsec cscli decisions delete --ip "$IP"
