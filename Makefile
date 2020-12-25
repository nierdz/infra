SHELL := /usr/bin/env bash
MAIN_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
VIRTUALENV_DIR := $(MAIN_DIR)/venv
PROJECT_NAME ?= none
USER := kmet
SERVER := srv1.igln.fr
SHELLCHECK_VERSION=0.7.1

help: ## Print this help
	@grep -E '^[a-zA-Z1-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

up: ## Make a docker-compose up
	$(info --> Make a docker-compose up)
	@docker-compose -f docker-compose-$(PROJECT_NAME).yml -p $(PROJECT_NAME) up -d

down: ## Make a docker-compose down
	$(info --> Make a docker-compose down)
	@docker-compose -f docker-compose-$(PROJECT_NAME).yml -p $(PROJECT_NAME) down

restart: ## Make a docker-compose down and up
	$(info --> Make a docker-compose down and  up)
	@docker-compose -f docker-compose-$(PROJECT_NAME).yml -p $(PROJECT_NAME) down
	@docker-compose -f docker-compose-$(PROJECT_NAME).yml -p $(PROJECT_NAME) up -d

rsync-pull: ## Pull files from server
	$(info --> Pull files from server)
	@rsync -avz --exclude-from "rsync-exclude.list" $(USER)@$(SERVER):/infra-docker/ .

rsync-push: ## Push files to server
	$(info --> Push files to server)
	@rsync -avz --exclude-from "rsync-exclude.list" --rsync-path="sudo rsync" . $(USER)@$(SERVER):/infra-docker/

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
		ansible-galaxy install -f -r ansible/requirements.yml -p ansible/vendor/roles; \
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
		&& ansible-playbook --diff ansible/playbook.yml
