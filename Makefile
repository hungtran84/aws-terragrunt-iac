.PHONY: help check-versions install-tools fmt plan apply destroy validate
.PHONY: plan-layer apply-layer destroy-layer validate-layer
.PHONY: plan-foundation apply-foundation destroy-foundation
.PHONY: plan-env apply-env destroy-env validate-env

# Default environment and region (can be overridden)
ENV ?= dev
REGION ?= ap-southeast-1
LAYER ?= layer0-foundation

help: ## Show this help message
	@echo 'Usage: make [target] [ENV=dev] [REGION=ap-southeast-1] [LAYER=layer0-foundation]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ''
	@echo 'Examples:'
	@echo '  make plan-foundation ENV=dev REGION=ap-southeast-1'
	@echo '  make apply-layer ENV=dev REGION=ap-southeast-1 LAYER=layer1-networking'
	@echo '  make plan-env ENV=dev REGION=ap-southeast-1'

check-versions: ## Check if Terraform and Terragrunt versions are correct
	@./scripts/check-versions.sh

install-tools: ## Check versions and auto-install Terraform and Terragrunt if missing
	@./scripts/check-versions.sh --auto-install

fmt: ## Format all terragrunt and terraform files
	@find . -name "*.tf" -o -name "*.hcl" | xargs terraform fmt -recursive

# Foundation layer operations (S3 and DynamoDB)
plan-foundation: ## Plan foundation layer (S3 and DynamoDB) for specified ENV and REGION
	@echo "Planning foundation layer for $(ENV)/$(REGION)..."
	@cd live/$(ENV)/$(REGION)/layer0-foundation && terragrunt run-all plan

apply-foundation: ## Apply foundation layer (S3 and DynamoDB) for specified ENV and REGION
	@echo "Applying foundation layer for $(ENV)/$(REGION)..."
	@cd live/$(ENV)/$(REGION)/layer0-foundation && terragrunt run-all apply

destroy-foundation: ## Destroy foundation layer (S3 and DynamoDB) for specified ENV and REGION
	@echo "Destroying foundation layer for $(ENV)/$(REGION)..."
	@cd live/$(ENV)/$(REGION)/layer0-foundation && terragrunt run-all destroy

validate-foundation: ## Validate foundation layer for specified ENV and REGION
	@echo "Validating foundation layer for $(ENV)/$(REGION)..."
	@cd live/$(ENV)/$(REGION)/layer0-foundation && terragrunt run-all validate

# Generic layer operations
plan-layer: ## Plan specified layer for ENV and REGION
	@echo "Planning $(LAYER) for $(ENV)/$(REGION)..."
	@cd live/$(ENV)/$(REGION)/$(LAYER) && terragrunt run-all plan

apply-layer: ## Apply specified layer for ENV and REGION
	@echo "Applying $(LAYER) for $(ENV)/$(REGION)..."
	@cd live/$(ENV)/$(REGION)/$(LAYER) && terragrunt run-all apply

destroy-layer: ## Destroy specified layer for ENV and REGION
	@echo "Destroying $(LAYER) for $(ENV)/$(REGION)..."
	@cd live/$(ENV)/$(REGION)/$(LAYER) && terragrunt run-all destroy

validate-layer: ## Validate specified layer for ENV and REGION
	@echo "Validating $(LAYER) for $(ENV)/$(REGION)..."
	@cd live/$(ENV)/$(REGION)/$(LAYER) && terragrunt run-all validate

# Environment/Region operations (all layers)
plan-env: ## Plan all layers for specified ENV and REGION
	@echo "Planning all layers for $(ENV)/$(REGION)..."
	@cd live/$(ENV)/$(REGION) && \
		for layer in layer0-foundation layer1-networking layer2-workloads layer3-apps; do \
			if [ -d "$$layer" ]; then \
				echo "Planning $$layer..."; \
				cd $$layer && terragrunt run-all plan && cd ..; \
			fi; \
		done

apply-env: ## Apply all layers for specified ENV and REGION (in order)
	@echo "Applying all layers for $(ENV)/$(REGION)..."
	@cd live/$(ENV)/$(REGION) && \
		for layer in layer0-foundation layer1-networking layer2-workloads layer3-apps; do \
			if [ -d "$$layer" ]; then \
				echo "Applying $$layer..."; \
				cd $$layer && terragrunt run-all apply && cd ..; \
			fi; \
		done

destroy-env: ## Destroy all layers for specified ENV and REGION (in reverse order)
	@echo "Destroying all layers for $(ENV)/$(REGION)..."
	@cd live/$(ENV)/$(REGION) && \
		for layer in layer3-apps layer2-workloads layer1-networking layer0-foundation; do \
			if [ -d "$$layer" ]; then \
				echo "Destroying $$layer..."; \
				cd $$layer && terragrunt run-all destroy && cd ..; \
			fi; \
		done

validate-env: ## Validate all layers for specified ENV and REGION
	@echo "Validating all layers for $(ENV)/$(REGION)..."
	@cd live/$(ENV)/$(REGION) && \
		for layer in layer0-foundation layer1-networking layer2-workloads layer3-apps; do \
			if [ -d "$$layer" ]; then \
				echo "Validating $$layer..."; \
				cd $$layer && terragrunt run-all validate && cd ..; \
			fi; \
		done

# Current directory operations (for when you're already in a layer directory)
plan: ## Run terragrunt plan in current directory
	@terragrunt plan

apply: ## Run terragrunt apply in current directory
	@terragrunt apply

destroy: ## Run terragrunt destroy in current directory
	@terragrunt destroy

validate: ## Run terragrunt validate in current directory
	@terragrunt validate

