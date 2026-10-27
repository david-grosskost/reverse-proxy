# git: repository tooling.

GIT_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

.PHONY: git@hooks

git@hooks:
	@$(GIT_SCRIPTS)/git/hooks.sh

git@gitleaks:
	@$(GIT_SCRIPTS)/git/gitleaks.sh