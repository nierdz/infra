MAIN_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
VIRTUALENV_DIR := $(MAIN_DIR)/venv
PATH := $(PATH):$(HOME)/.local/bin
SHELL := /usr/bin/env bash

help: ## Print this help
	@grep -E '^[a-zA-Z1-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

install: ## Install everything
	$(info --> Install everything)
	@$(MAKE) install-ansible
	@$(MAKE) ansible-galaxy-install

install-ansible: ## Install ansible via pip
	$(info --> Install ansible via `pip`)
	@$(MAKE) venv
	@( \
		source $(VIRTUALENV_DIR)/bin/activate; \
		pip3 install --upgrade setuptools; \
		pip3 install -r requirements.txt; \
	)

venv: ## Create python virtualenv if not exists
	[[ -d $(VIRTUALENV_DIR) ]] || virtualenv --system-site-packages $(VIRTUALENV_DIR)

ansible-lint: ## Run ansible-lint on all roles
	$(info --> Run ansible-lint on all roles)
	@( \
		source $(VIRTUALENV_DIR)/bin/activate; \
		ansible-lint playbook.yml; \
		ansible-playbook playbook.yml --syntax-check; \
		yamllint -c .yamllint.yml .; \
		pre-commit run --all-files; \
	)

travis-lint: ## Run ansible-lint on travis
	$(info --> Run ansible-lint on travis)
	@export \
		ANSIBLE_VAULT_PASSWORD=$(ANSIBLE_VAULT_PASSWORD) \
		&& source $(VIRTUALENV_DIR)/bin/activate \
		&& ansible-lint -v playbook.yml \
		&& yamllint -c .yamllint.yml .

ansible-galaxy-install: ## Install ansible galaxy dependencies
	$(info --> Install ansible galaxy dependencies)
	@( \
		source $(VIRTUALENV_DIR)/bin/activate; \
		ansible-galaxy install -f -r requirements.yml -p vendor/roles; \
	)

run-ansible: ## Run ansible on all servers
	$(info --> Run ansible on all servers)
	@export \
		ANSIBLE_STRATEGY_PLUGINS=venv/lib/python2.7/site-packages/ansible_mitogen/plugins/strategy \
		&& ANSIBLE_STRATEGY=mitogen_linear \
		&& source $(VIRTUALENV_DIR)/bin/activate \
		&& ansible-playbook --diff playbook.yml
