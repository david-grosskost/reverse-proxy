# app: reverse proxy lifecycle.

APP_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

# Defaults to .env, then local. Override: make app@start APP_ENV=prod
APP_ENV ?=

# Service followed by app@logs: make app@logs SERVICE=socket-proxy
SERVICE ?= traefik
export APP_ENV SERVICE

.PHONY: app@start app@stop app@restart app@status app@logs app@update app@config

app@start:
	@$(APP_SCRIPTS)/app/start.sh

app@stop:
	@$(APP_SCRIPTS)/app/stop.sh

app@restart:
	@$(APP_SCRIPTS)/app/restart.sh

app@status:
	@$(APP_SCRIPTS)/app/status.sh

app@logs:
	@$(APP_SCRIPTS)/app/logs.sh

app@update:
	@$(APP_SCRIPTS)/app/update.sh

app@config:
	@$(APP_SCRIPTS)/app/config.sh
