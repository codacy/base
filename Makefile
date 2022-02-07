DOCKER_IMAGE_NAME=codacy/base

VERSION?=$(shell cat .version || echo dev)

all: docker_build ## produce the docker image

docker_build: ## build the docker image
	docker build --no-cache -t $(DOCKER_IMAGE_NAME):$(VERSION) .

.PHONY: push-docker-image
push-docker-image: ## push the docker image to the registry (DOCKER_USER and DOCKER_PASS mandatory)
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS) &&\
	docker push $(DOCKER_IMAGE_NAME):$(VERSION)

.PHONY: push-latest-docker-image
push-latest-docker-image: ## push the docker image with the "latest" tag to the registry (DOCKER_USER and DOCKER_PASS mandatory)
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS) &&\
	docker tag $(DOCKER_IMAGE_NAME):$(VERSION) $(DOCKER_IMAGE_NAME):latest &&\
	docker push $(DOCKER_IMAGE_NAME):latest

.PHONY: help
help:
	@echo "make help"
	@echo "\n"
	@grep -E '^[a-zA-Z_/%\-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo "\n"
