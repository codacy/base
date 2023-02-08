JDK_IMAGE_NAME=codacy/openjdk
BASE_IMAGE_NAME=codacy/base
WITHTOOLS_IMAGE_NAME=codacy/withtools

OPENJDK_VERSION=8
VERSION?=$(shell cat .version || echo dev)
OPENJ9_VERSION?=openj9-$(VERSION)
BASE_IMAGE_OPENJDK=codacy/openjdk:$(OPENJDK_VERSION)
BASE_IMAGE_OPENJ9=adoptopenjdk/openjdk8-openj9:x86_64-ubuntu-jre8u332-b09_openj9-0.32.0

all: docker_build ## produce the docker image

docker_build: ## build the docker image
	docker build --build-arg --no-cache -t $(JDK_IMAGE_NAME):$(OPENJDK_VERSION) ./openjdk/

	docker build --build-arg base_image=$(BASE_IMAGE_OPENJDK) --no-cache -t $(BASE_IMAGE_NAME):$(VERSION) --target base ./base/
	docker build --build-arg base_image=$(BASE_IMAGE_OPENJ9) --no-cache -t $(BASE_IMAGE_NAME):$(OPENJ9_VERSION) --target base ./base/

	docker build --build-arg base_image=$(BASE_IMAGE_OPENJDK) --no-cache -t $(WITHTOOLS_IMAGE_NAME):$(VERSION) --target withtools ./base/
	docker build --build-arg base_image=$(BASE_IMAGE_OPENJ9) --no-cache -t $(WITHTOOLS_IMAGE_NAME):$(OPENJ9_VERSION) --target withtools ./base/

docker_scan: ## scan the docker image for security vulnerabilities
	docker scan --accept-license --login --token $(DOCKER_SCAN_SNYK_TOKEN) &&\
	docker scan --accept-license --severity high $(BASE_IMAGE_NAME):$(VERSION)
	docker scan --accept-license --severity high $(BASE_IMAGE_NAME):$(OPENJ9_VERSION)
	docker scan --accept-license --severity high $(WITHTOOLS_IMAGE_NAME):$(VERSION)
	docker scan --accept-license --severity high $(WITHTOOLS_IMAGE_NAME):$(OPENJ9_VERSION)

.PHONY: push-docker-image
push-docker-image: ## push the docker image to the registry (DOCKER_USER and DOCKER_PASS mandatory)
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS) &&\
	docker push $(BASE_IMAGE_NAME):$(VERSION)
	docker push $(BASE_IMAGE_NAME):$(OPENJ9_VERSION)
	docker push $(WITHTOOLS_IMAGE_NAME):$(VERSION)
	docker push $(WITHTOOLS_IMAGE_NAME):$(OPENJ9_VERSION)

.PHONY: push-latest-docker-image
push-latest-docker-image: ## push the docker image with the "latest" tag to the registry (DOCKER_USER and DOCKER_PASS mandatory)
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS) &&\
	docker tag $(BASE_IMAGE_NAME):$(VERSION) $(BASE_IMAGE_NAME):latest &&\
	docker tag $(WITHTOOLS_IMAGE_NAME):$(VERSION) $(WITHTOOLS_IMAGE_NAME):latest &&\
	docker push $(BASE_IMAGE_NAME):latest &&\
	docker push $(WITHTOOLS_IMAGE_NAME):latest

.PHONY: help
help:
	@echo "make help"
	@echo "\n"
	@grep -E '^[a-zA-Z_/%\-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo "\n"
