# cert: local HTTPS certificates (mkcert). Production uses Let's Encrypt.

CERT_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

.PHONY: cert@install cert@create

cert@install:
	@$(CERT_SCRIPTS)/cert/install.sh

cert@create:
	@$(CERT_SCRIPTS)/cert/create.sh
