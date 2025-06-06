# Variables
CLUSTER_NAME ?= iac-controller-cluster
K8S_VERSION ?= kindest/node:v1.33.0

LOCALSTACK_PORT ?= 4566

##@ General

.DEFAULT_GOAL := help


# Needed to forward extra args to target
%:
	@:

.PHONY: help
help: ## Show help for make targets
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


.PHONY: bootstrap
bootstrap: ## Create KinD cluster, install Flux, install Tofu Controller, apply Terraform resources
	@$(MAKE) create-cluster
	@$(MAKE) localstack-up
	@$(MAKE) install-flux
	@$(MAKE) install-tofu-controller
	@$(MAKE) apply-flux-tf

##@ LocalStack

.PHONY: localstack-up
localstack-up: ## Start LocalStack container using Helm
	@if ! helm repo list | grep -q 'localstack-charts'; then \
		helm repo add localstack-charts https://localstack.github.io/helm-charts; \
	fi
	@helm repo update
	@if ! helm list -n localstack | grep -q 'localstack'; then \
		helm upgrade --install localstack localstack-charts/localstack \
			--namespace localstack \
			--create-namespace \
			--set service.type=ClusterIP; \
	fi



.PHONY: localstack-port-forward
localstack-port-forward: ## Port-forward LocalStack service
	kubectl port-forward svc/localstack 4566:4566 -n localstack


##@ Cluster
.PHONY: create-cluster
create-cluster: ## Create a KinD cluster with NodePort mapped to host
	@kind create cluster --name $(CLUSTER_NAME) --image $(K8S_VERSION) --config=./kind-config.yaml

.PHONY: delete-cluster
delete-cluster: ## Delete the KinD cluster
	kind delete cluster --name $(CLUSTER_NAME)

##@ Flux

.PHONY: install-flux
install-flux: ## Install Flux CLI into cluster
	@docker run --rm -it \
		--network host \
		-v $(HOME)/.kube:/kube:Z \
		ghcr.io/fluxcd/flux-cli:v2.5.0 \
		install --namespace flux-system --kubeconfig=/kube/config





##@ Tofu Controller

.PHONY: install-tofu-controller
install-tofu-controller: ## Install Tofu Controller into the cluster
	kubectl apply -f https://raw.githubusercontent.com/flux-iac/tofu-controller/main/docs/release.yaml

##@ Flux-TF Resources

.PHONY: apply-flux-tf
apply-flux-tf: ## Apply flux-tf-yaml resources
	@until kubectl get crd terraforms.infra.contrib.fluxcd.io; do \
		echo "⏳ Waiting for Terraform CRD to be ready..."; \
		sleep 5; \
	done
	@kubectl apply -k ./flux-tf-yaml

.PHONY: delete-flux-tf
delete-flux-tf: ## Delete flux-tf-yaml resources
	@kubectl delete -k ./flux-tf-yaml

.PHONY: tf-logs
tf-logs: ## Tail logs of the latest Terraform runner pod
	@POD=$$(kubectl get pods -n flux-system -l app.kubernetes.io/name=terraform --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}'); \
	if [ -z "$$POD" ]; then \
		echo "❌ No Terraform runner pod found."; \
		exit 0; \
	else \
		echo "📜 Tailing logs from pod: $$POD"; \
		kubectl logs -f -n flux-system $$POD; \
	fi


##@ AWS CLI Helpers

.PHONY: awscli
awscli: ## Run AWS CLI container against LocalStack (example: make awscli s3 ls)
	@docker run --rm -it \
		--network=host \
		-e AWS_ACCESS_KEY_ID=test \
		-e AWS_SECRET_ACCESS_KEY=test \
		-e AWS_DEFAULT_REGION=us-east-1 \
		docker.io/amazon/aws-cli \
		--endpoint-url=http://localhost:4566 $(filter-out $@,$(MAKECMDGOALS))





