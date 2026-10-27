#!/usr/bin/env bash
# Lists the IPs currently blocked by CrowdSec, and why.
#
# @usage make waf@decisions
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env waf@decisions

compose exec -T crowdsec cscli decisions list
