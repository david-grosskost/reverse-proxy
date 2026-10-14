# network: the shared "proxy" Docker network.

NETWORK_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

.PHONY: network@create network@ls

network@create:
	@$(NETWORK_SCRIPTS)/network/create.sh

network@ls:
	@$(NETWORK_SCRIPTS)/network/ls.sh
