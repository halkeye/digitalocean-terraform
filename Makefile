#!make
.DEFAULT_GOAL := help

.PHONY: plan apply help all fmt

all: plan apply

plan: ## Plan resources changes
	terraform plan -out plan.out

apply: ## Execute resources changes
	terraform apply plan.out

fmt: ## Format
	terraform fmt provider.tf

show: ## Show current state
	terraform show

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
