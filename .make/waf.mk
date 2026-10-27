# waf: CrowdSec, the web application firewall and IP blocker.

WAF_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

# IP to unblock with waf@unban, site to test with waf@test.
IP ?=
SITE ?=
export IP SITE

.PHONY: waf@key waf@decisions waf@unban waf@metrics waf@test

waf@key:
	@$(WAF_SCRIPTS)/waf/key.sh

waf@decisions:
	@$(WAF_SCRIPTS)/waf/decisions.sh

waf@unban:
	@$(WAF_SCRIPTS)/waf/unban.sh

waf@metrics:
	@$(WAF_SCRIPTS)/waf/metrics.sh

waf@test:
	@$(WAF_SCRIPTS)/waf/test.sh
