SHELL := /usr/bin/env bash
ANSIBLE_INVENTORY_GROUP ?= all
ANSIBLE_TAGS ?= all
MAIN_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
VIRTUALENV_DIR := $(MAIN_DIR)/venv
PROJECT_NAME ?= none
USER := kmet
SERVER := srv1.igln.fr

help: ## Print this help
	@grep -E '^[a-zA-Z1-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

rsync-pull: ## Pull files from server
	$(info --> Pull files from server)
	@rsync -avz --exclude-from ".gitignore" --exclude ".git" $(USER)@$(SERVER):/infra/ .

rsync-push: ## Push files to server
	$(info --> Push files to server)
	@rsync -avz --exclude-from ".gitignore" --exclude ".git" --rsync-path="sudo rsync" . $(USER)@$(SERVER):/infra/

docker-build: ##Build all images in docker folder
	$(info --> Build all images in docker folder)
	@scripts/docker-build.sh

venv: ## Create python virtualenv if not exists
	@[[ -d $(VIRTUALENV_DIR) ]] || python3 -m virtualenv --system-site-packages $(VIRTUALENV_DIR)

install: ## Install pip and ansible dependencies
	$(info --> Install pip and ansible dependencies)
	@$(MAKE) venv
	@( \
		source $(VIRTUALENV_DIR)/bin/activate; \
		pip3 install --upgrade setuptools; \
		pip3 install -r requirements.txt; \
		ansible-galaxy install -r ansible/requirements.yml -p ansible/vendor/roles; \
	)

pre-commit: ## Run pre-commit tests
	$(info --> Run pre-commit)
	@( \
		source $(VIRTUALENV_DIR)/bin/activate; \
		pre-commit run --all-files; \
	)

run-ansible: ## Run ansible on all servers
	$(info --> Run ansible on all servers)
	@export \
		ANSIBLE_CONFIG=ansible/ansible.cfg \
		&& ANSIBLE_STRATEGY_PLUGINS=venv/lib/python3.8/site-packages/ansible_mitogen/plugins/strategy \
		&& ANSIBLE_STRATEGY=mitogen_linear \
		&& source $(VIRTUALENV_DIR)/bin/activate \
		&& ansible-playbook -l $(ANSIBLE_INVENTORY_GROUP) -t $(ANSIBLE_TAGS) --diff ansible/playbook.yml
