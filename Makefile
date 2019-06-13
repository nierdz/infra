SHELL := /usr/bin/env bash
PROJECT_NAME ?= none

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
