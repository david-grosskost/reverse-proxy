#!/usr/bin/env bash
# Shows what CrowdSec has analysed: requests checked and blocked by the WAF,
# log lines parsed, scenarios triggered.
#
# @usage make waf@metrics
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env waf@metrics

compose exec -T crowdsec cscli metrics show appsec acquisition scenarios
