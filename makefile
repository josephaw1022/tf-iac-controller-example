# Variables
CLUSTER_NAME ?= iac-controller-cluster
K8S_VERSION ?= kindest/node:v1.33.0
FLUX_VERSION ?= v2.5.1
FLUX_IMAGE ?= fluxcd/flux-cli:$(FLUX_VERSION)-amd64

LOCALSTACK_PORT ?= 4566
PODMAN_SOCKET_PATH ?= /usr/lib/systemd/system/podman.socket
MOUNT_PODMAN_SOCKET ?= true

##@ General

# Needed to forward extra args to target
%:
	@:

.PHONY: help
help: ## Show help for make targets
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

##@ LocalStack

.PHONY: localstack-up
localstack-up: ## Start LocalStack container using Podman socket (optional)
	@if [ "$(MOUNT_PODMAN_SOCKET)" = "true" ]; then \
		docker run -d --name localstack --replace \
		-p 127.0.0.1:$(LOCALSTACK_PORT):$(LOCALSTACK_PORT) \
		-p 127.0.0.1:4510-4559:4510-4559 \
		-v $(PODMAN_SOCKET_PATH):/var/run/docker.sock \
		docker.io/localstack/localstack; \
	else \
		docker run -d --name localstack --replace \
		-p 127.0.0.1:$(LOCALSTACK_PORT):$(LOCALSTACK_PORT) \
		-p 127.0.0.1:4510-4559:4510-4559 \
		docker.io/localstack/localstack; \
	fi

.PHONY: localstack-down
localstack-down: ## Stop and remove LocalStack container
	docker rm -f localstack

##@ Cluster

.PHONY: create-cluster
create-cluster: ## Create a KinD cluster
	kind create cluster --name $(CLUSTER_NAME) --image $(K8S_VERSION)

.PHONY: delete-cluster
delete-cluster: ## Delete the KinD cluster
	kind delete cluster --name $(CLUSTER_NAME)

##@ Flux

.PHONY: install-flux
install-flux: ## Install Flux CLI into cluster using Podman
	podman run --rm -it \
		--network host \
		-v $(HOME)/.kube:/root/.kube:Z \
		$(FLUX_IMAGE) \
		flux install

##@ Tofu Controller

.PHONY: install-tofu-controller
install-tofu-controller: ## Install Tofu Controller into the cluster
	kubectl apply -f https://raw.githubusercontent.com/flux-iac/tofu-controller/main/docs/release.yaml

##@ Flux-TF Resources

.PHONY: apply-flux-tf
apply-flux-tf: ## Apply flux-tf-yaml resources
	kubectl apply -k ./flux-tf-yaml

.PHONY: delete-flux-tf
delete-flux-tf: ## Delete flux-tf-yaml resources
	kubectl delete -k ./flux-tf-yaml

##@ AWS CLI Helpers

.PHONY: aws-env
aws-env: ## Export AWS env vars for LocalStack
	@export AWS_ACCESS_KEY_ID=test && \
	export AWS_SECRET_ACCESS_KEY=test && \
	export AWS_DEFAULT_REGION=us-east-1 && \
	echo "✅ AWS environment variables set for LocalStack."

.PHONY: aws-env-unset
aws-env-unset: ## Unset AWS env vars
	@unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION && \
	echo "✅ AWS environment variables unset."

.PHONY: awscli
awscli: ## Run aws cli against LocalStack (example: make awscli s3 ls)
	@aws --endpoint-url=http://localhost:$(LOCALSTACK_PORT) $(filter-out $@,$(MAKECMDGOALS))
