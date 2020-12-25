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

build: ##Build all images in docker folder
	$(info --> Build all images in docker folder)
	@scripts/docker-build.sh

venv: ## Create python virtualenv if not exists
	@[[ -d $(VIRTUALENV_DIR) ]] || python3 -m virtualenv --system-site-packages $(VIRTUALENV_DIR)

pip-install: ## Install pip dependencies
	$(info --> Install pip dependencies)
	@$(MAKE) venv
	@( \
		source $(VIRTUALENV_DIR)/bin/activate; \
		pip3 install --upgrade setuptools; \
		pip3 install -r requirements.txt; \
	)

binaries-install: ## Download and install binaries for CI
	$(info --> Download and install binaries for CI)
	@( \
		wget -qO- 'https://github.com/koalaman/shellcheck/releases/download/v0.7.1/shellcheck-v$(SHELLCHECK_VERSION).linux.x86_64.tar.xz' | tar -xJv; \
		sudo mv "shellcheck-v$(SHELLCHECK_VERSION)/shellcheck" /usr/bin/shellcheck; \
		sudo chmod +x /usr/bin/shellcheck; \
	)

install: pip-install binaries-install## Install everything

pre-commit: ## Run pre-commit tests
	$(info --> Run pre-commit)
	@( \
		source $(VIRTUALENV_DIR)/bin/activate; \
		pre-commit run --all-files; \
	)

shellcheck: ## Run shellcheck on all scripts
	$(info --> Run shellcheck on all scripts)
	@find scripts/ -type f | xargs -n 1 shellcheck

docker-lint: ## Run hadolint on docker files
	$(info --> Run hadolint on docker files)
	@scripts/docker-lint.sh

tests: pre-commit shellcheck docker-lint ## Run all tests
	$(info --> Run all tests)
