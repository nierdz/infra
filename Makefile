SHELL := /usr/bin/env bash
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
