SHELL := /usr/bin/env bash

help: ## Print this help
	@grep -E '^[a-zA-Z1-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

fix-permissions: ## To use during first install
	$(info --> Fix permissions for first install)
		@( \
			chown -R root:root .; \
			find . -type d -exec chmod 755 {} \;; \
			find . -type f -exec chmod 644 {} \;; \
			chown -R www-data:www-data madrabbit; \
			chmod 0600 .env; \
		)
