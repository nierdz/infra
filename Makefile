SHELL := /usr/bin/env bash
ANSIBLE_INVENTORY_GROUP ?= all
ANSIBLE_ARGS ?= -v
MAIN_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
VIRTUALENV_DIR := $(MAIN_DIR)/venv
ANSIBLE_DIR := $(MAIN_DIR)/ansible
USER := kmet
SERVER := srv2.igln.fr
PATH := $(VIRTUALENV_DIR)/bin:$(PATH)

help: ## Print this help
	@grep -E '^[a-zA-Z1-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

$(VIRTUALENV_DIR):
	virtualenv -p $(shell command -v python3) $(VIRTUALENV_DIR)

$(VIRTUALENV_DIR)/bin/pre-commit: $(MAIN_DIR)/requirements.txt
	pip install -r $(MAIN_DIR)/requirements.txt
	@touch '$(@)'

pre-commit-install: ## Install pre-commit hooks
	pre-commit install

install-pip-packages: $(VIRTUALENV_DIR) $(VIRTUALENV_DIR)/bin/pre-commit ## Install python pip packages in a virtual environment

$(ANSIBLE_DIR)/vendor: $(ANSIBLE_DIR)/requirements.yml ## Install ansible galaxy dependencies
	ansible-galaxy install --force -r $(ANSIBLE_DIR)/requirements.yml -p $(ANSIBLE_DIR)/vendor/roles;
	@touch '$(@)'

install: install-pip-packages $(ANSIBLE_DIR)/vendor

rsync-pull: ## Pull files from server
	rsync -avz --exclude-from ".gitignore" --exclude ".git" $(USER)@$(SERVER):/infra/ .

rsync-push: ## Push files to server
	rsync -avz --exclude-from ".gitignore" --exclude ".git" --rsync-path="sudo rsync" . $(USER)@$(SERVER):/infra/

docker-build: ## Build all images in docker folder
	scripts/docker-build.sh

docker-run-igln-local: ## Build and run igln.fr container locally
	docker rm -f igln-local
	docker build \
		--build-arg LOCAL=1 \
		-t igln.fr:local \
		$(MAIN_DIR)/docker/igln.fr
	docker run -d \
		-p 127.0.0.1:443:443 \
		--name igln-local \
		-v $(MAIN_DIR)/docker/igln.fr/igln.conf:/etc/nginx/conf.d/igln.conf:ro \
		-v $(MAIN_DIR)/certs/igln.local-key.pem:/etc/ssl/certs/igln.local-key.pem:ro \
		-v $(MAIN_DIR)/certs/igln.local.pem:/etc/ssl/certs/igln.local.pem:ro \
		igln.fr:local

mkcert: ## Create certs if needed
	if [[ -e $(MAIN_DIR)/certs/igln.local-key.pem ]] && [[ -e $(MAIN_DIR)/certs/igln.local.pem ]]; then \
		openssl verify -CAfile ~/.local/share/mkcert/rootCA.pem $(MAIN_DIR)/certs/igln.local.pem; \
	else \
		mkcert \
			-cert-file $(MAIN_DIR)/certs/igln.local.pem \
			-key-file $(MAIN_DIR)/certs/igln.local-key.pem \
			"igln.local"; \
	fi

pre-commit: ## Run pre-commit tests
	pre-commit run --all-files

ansible-run: ## Run ansible on all servers
	pushd $(ANSIBLE_DIR); \
	ANSIBLE_STRATEGY_PLUGINS=venv/lib/python3.8/site-packages/ansible_mitogen/plugins/strategy; \
	ANSIBLE_STRATEGY=mitogen_linear; \
	ansible-playbook -l $(ANSIBLE_INVENTORY_GROUP) $(ANSIBLE_ARGS) --diff playbook.yml;

ansible-lint: ## Run ansible-lint
	ANSIBLE_ROLES_PATH=$(ANSIBLE_DIR)/roles:$(ANSIBLE_DIR)/vendor/roles \
		ansible-lint -v -c .ansible-lint $(ANSIBLE_DIR)/playbook.yml
