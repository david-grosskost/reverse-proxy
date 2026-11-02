# cert: local HTTPS certificates (mkcert), and the DNS provider credentials used
# in prod to obtain the Let's Encrypt wildcard certificate.

CERT_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

.PHONY: cert@install cert@create cert@mkcert cert@dns

cert@install:
	@$(CERT_SCRIPTS)/cert/install.sh

cert@create:
	@$(CERT_SCRIPTS)/cert/create.sh

cert@mkcert:
	@$(CERT_SCRIPTS)/cert/mkcert.sh

cert@dns:
	@$(CERT_SCRIPTS)/cert/dns.sh
