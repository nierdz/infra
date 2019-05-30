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
		pip install --upgrade setuptools; \
		pip install -r requirements.txt; \
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
	)

ansible-galaxy-install: ## Install ansible galaxy dependencies
	$(info --> Install ansible galaxy dependencies)
	@( \
		source $(VIRTUALENV_DIR)/bin/activate; \
		ansible-galaxy install -r requirements.yml -p vendor/roles; \
	)
