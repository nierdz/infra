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

docker-build: ## Build all images in docker folder
	$(info --> Build all images in docker folder)
	@scripts/docker-build.sh

docker-run-igln-local: ## Build and run igln.fr container locally
	$(info --> Build and run igln.fr container locally)
	@docker rm -f igln-local
	@docker build \
		--build-arg LOCAL=1 \
		-t igln.fr:local \
		$(MAIN_DIR)/docker/igln.fr
	@docker run -d \
		-p 127.0.0.1:443:443 \
		--name igln-local \
		-v $(MAIN_DIR)/docker/igln.fr/igln.conf:/etc/nginx/conf.d/igln.conf:ro \
		-v $(MAIN_DIR)/certs/igln.local-key.pem:/etc/ssl/certs/igln.local-key.pem:ro \
		-v $(MAIN_DIR)/certs/igln.local.pem:/etc/ssl/certs/igln.local.pem:ro \
		igln.fr:local

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

mkcert: ## Create certs if needed
	$(info --> Create certs if needed)
	@if [[ -e $(MAIN_DIR)/certs/igln.local-key.pem ]] && [[ -e $(MAIN_DIR)/certs/igln.local.pem ]]; then \
		openssl verify -CAfile ~/.local/share/mkcert/rootCA.pem $(MAIN_DIR)/certs/igln.local.pem; \
	else \
		mkcert \
			-cert-file $(MAIN_DIR)/certs/igln.local.pem \
			-key-file $(MAIN_DIR)/certs/igln.local-key.pem \
			"igln.local"; \
	fi; \

pre-commit: ## Run pre-commit tests
	$(info --> Run pre-commit)
	@( \
		source $(VIRTUALENV_DIR)/bin/activate; \
		pre-commit run --all-files; \
	)

ansible-run: ## Run ansible on all servers
	$(info --> Run ansible on all servers)
	@export \
		ANSIBLE_CONFIG=ansible/ansible.cfg \
		&& ANSIBLE_STRATEGY_PLUGINS=venv/lib/python3.8/site-packages/ansible_mitogen/plugins/strategy \
		&& ANSIBLE_STRATEGY=mitogen_linear \
		&& source $(VIRTUALENV_DIR)/bin/activate \
		&& ansible-playbook -l $(ANSIBLE_INVENTORY_GROUP) -t $(ANSIBLE_TAGS) --diff ansible/playbook.yml

ansible-lint: ## Run ansible-lint
	$(info --> Run ansible-lint)
	@( \
		source $(VIRTUALENV_DIR)/bin/activate; \
		ansible-lint ansible/playbook.yml; \
	)
