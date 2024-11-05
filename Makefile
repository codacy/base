BASE_IMAGE_NAME=codacy/base
WITHTOOLS_IMAGE_NAME=codacy/withtools

VERSION?=$(shell cat .version || echo dev)
OPENJ9_VERSION?=openj9-$(VERSION)
OPENJDK17_VERSION?=jre17-$(VERSION)
BASE_IMAGE_OPENJDK=adoptopenjdk/openjdk8:x86_64-ubuntu-jre8u432-b06
BASE_IMAGE_OPENJDK17=eclipse-temurin:17.0.12_7-jdk-focal
BASE_IMAGE_OPENJ9=adoptopenjdk/openjdk8-openj9:x86_64-ubuntu-jre8u422-b05_openj9-0.46.1

all: docker_build ## produce the docker image

docker_build: ## build the docker image
	docker build --build-arg base_image=$(BASE_IMAGE_OPENJDK) --no-cache -t $(BASE_IMAGE_NAME):$(VERSION) --target base .
	docker build --build-arg base_image=$(BASE_IMAGE_OPENJ9) --no-cache -t $(BASE_IMAGE_NAME):$(OPENJ9_VERSION) --target base .
	docker build --build-arg base_image=$(BASE_IMAGE_OPENJDK17) --no-cache -t $(BASE_IMAGE_NAME):$(OPENJDK17_VERSION) --target base .

	docker build --build-arg base_image=$(BASE_IMAGE_OPENJDK) --no-cache -t $(WITHTOOLS_IMAGE_NAME):$(VERSION) --target withtools .
	docker build --build-arg base_image=$(BASE_IMAGE_OPENJ9) --no-cache -t $(WITHTOOLS_IMAGE_NAME):$(OPENJ9_VERSION) --target withtools .
	docker build --build-arg base_image=$(BASE_IMAGE_OPENJDK17) --no-cache -t $(WITHTOOLS_IMAGE_NAME):$(OPENJDK17_VERSION) --target withtools .

docker_scan: ## scan the docker image for security vulnerabilities
	docker scan --accept-license --login --token $(DOCKER_SCAN_SNYK_TOKEN) &&\
	docker scan --accept-license --severity high $(BASE_IMAGE_NAME):$(VERSION)
	docker scan --accept-license --severity high $(BASE_IMAGE_NAME):$(OPENJ9_VERSION)
	docker scan --accept-license --severity high $(BASE_IMAGE_NAME):$(OPENJDK17_VERSION)
	docker scan --accept-license --severity high $(WITHTOOLS_IMAGE_NAME):$(VERSION)
	docker scan --accept-license --severity high $(WITHTOOLS_IMAGE_NAME):$(OPENJ9_VERSION)
	docker scan --accept-license --severity high $(WITHTOOLS_IMAGE_NAME):$(OPENJDK17_VERSION)

.PHONY: push-docker-image
push-docker-image: ## push the docker image to the registry (DOCKER_USER and DOCKER_PASS mandatory)
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS) &&\
	docker push $(BASE_IMAGE_NAME):$(VERSION)
	docker push $(BASE_IMAGE_NAME):$(OPENJ9_VERSION)
	docker push $(BASE_IMAGE_NAME):$(OPENJDK17_VERSION)
	docker push $(WITHTOOLS_IMAGE_NAME):$(VERSION)
	docker push $(WITHTOOLS_IMAGE_NAME):$(OPENJ9_VERSION)
	docker push $(WITHTOOLS_IMAGE_NAME):$(OPENJDK17_VERSION)

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
