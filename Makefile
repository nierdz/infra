SHELL := /usr/bin/env bash
MAIN_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
VIRTUALENV_DIR := $(MAIN_DIR)/venv
PROJECT_NAME ?= none
USER := kmet
SERVER := srv1.igln.fr

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
	@[[ -d $(VIRTUALENV_DIR) ]] || virtualenv --system-site-packages $(VIRTUALENV_DIR)

pip-install: ## Install pip dependencies
	$(info --> Install pip dependencies)
	@$(MAKE) venv
	@( \
		source $(VIRTUALENV_DIR)/bin/activate; \
		pip install --upgrade setuptools; \
		pip install -r requirements.txt; \
	)

install: pip-install ## Install everything

pre-commit: ## Run pre-commit tests
	$(info --> Run pre-commit)
	@( \
		source $(VIRTUALENV_DIR)/bin/activate; \
		pre-commit run --all-files; \
	)

tests: pre-commit ## Run all tests
	$(info --> Run all tests)
