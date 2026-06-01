# Security-Learning-Hub v2 — developer entrypoints.
# All targets are local-dev oriented (k3d on the Mac). Registry/multi-arch is `make push`.

SHELL := /bin/bash
STUDENT_NS ?= lab-student-01
REGISTRY   ?= slh
TAG        ?= dev

.PHONY: help cluster-up cluster-down binfmt build slice-up slice-down shell push status validate

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

cluster-up: ## Create the local k3d cluster (installs k3d if needed)
	./deploy/cluster-local.sh

cluster-down: ## Delete the local k3d cluster
	k3d cluster delete $${SLH_CLUSTER:-slh-dev}

binfmt: ## Register QEMU binfmt so amd64-only images run on Apple Silicon
	./deploy/binfmt-setup.sh

build: ## Build images locally and import into the k3d cluster
	REGISTRY=$(REGISTRY) TAG=$(TAG) ./deploy/build-local.sh

slice-up: build ## Build + deploy the SQLi exercise + Kali shell into STUDENT_NS
	REGISTRY=$(REGISTRY) TAG=$(TAG) ./deploy/slice-up.sh $(STUDENT_NS)

slice-down: ## Tear down STUDENT_NS
	./deploy/slice-down.sh $(STUDENT_NS)

shell: ## Port-forward the browser shell for STUDENT_NS to http://localhost:7681
	@echo "Open http://localhost:7681  (Ctrl-C to stop)"
	kubectl port-forward -n $(STUDENT_NS) svc/kali-shell 7681:7681

status: ## Show what's running in STUDENT_NS
	kubectl get all,networkpolicy -n $(STUDENT_NS)

push: ## Build + push MULTI-ARCH images to REGISTRY (set REGISTRY=ghcr.io/you TAG=x)
	REGISTRY=$(REGISTRY) TAG=$(TAG) ./deploy/buildx-push.sh

validate: ## Client-side validate all rendered manifests (no cluster needed)
	./deploy/validate.sh
