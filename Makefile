#!make
.DEFAULT_GOAL := help

.PHONY: plan apply help all

all: plan apply

plan: ## Plan resources changes
	terraform plan -out plan.out

apply: ## Execute resources changes
	terraform apply plan.out

show: ## Execute resources changes
	terraform show

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
