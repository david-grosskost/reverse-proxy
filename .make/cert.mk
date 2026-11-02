# cert: local HTTPS certificates (mkcert), and the OVH API keys used in prod
# to obtain the Let's Encrypt wildcard certificate.

CERT_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

.PHONY: cert@install cert@create cert@mkcert cert@ovh

cert@install:
	@$(CERT_SCRIPTS)/cert/install.sh

cert@create:
	@$(CERT_SCRIPTS)/cert/create.sh

cert@mkcert:
	@$(CERT_SCRIPTS)/cert/mkcert.sh

cert@ovh:
	@$(CERT_SCRIPTS)/cert/ovh.sh
