BASE_IMAGE_NAME=codacy/base
WITHTOOLS_IMAGE_NAME=codacy/withtools

VERSION?=$(shell cat .version || echo dev)
OPENJDK17_VERSION?=jre17-$(VERSION)
OPENJDK25_VERSION?=jre25-$(VERSION)
BASE_IMAGE_OPENJDK17=eclipse-temurin:17.0.21.1_2-jre-jammy
BASE_IMAGE_OPENJDK25=eclipse-temurin:25.0.5.1_2-jre-jammy
# Java version a Temurin tag ships, e.g. eclipse-temurin:17.0.21.1_2-jre-jammy -> 17.0.21.1
temurin_java_version=$(firstword $(subst _, ,$(lastword $(subst :, ,$(1)))))
DOCKER_SCOUT_VERSION=1.29.0
DOCKER_SCOUT_SHA256=9157cdc9372b478a8cd51dd53f5e9c74a7e34056ea291c65520bf76016fa72f4

all: docker_build ## produce the docker image

docker_build: ## build the docker image
	docker build --build-arg base_image=$(BASE_IMAGE_OPENJDK17) --no-cache -t $(BASE_IMAGE_NAME):$(OPENJDK17_VERSION) --target base .
	docker build --build-arg base_image=$(BASE_IMAGE_OPENJDK25) --no-cache -t $(BASE_IMAGE_NAME):$(OPENJDK25_VERSION) --target base .

	docker build --build-arg base_image=$(BASE_IMAGE_OPENJDK17) --no-cache -t $(WITHTOOLS_IMAGE_NAME):$(OPENJDK17_VERSION) --target withtools .
	docker build --build-arg base_image=$(BASE_IMAGE_OPENJDK25) --no-cache -t $(WITHTOOLS_IMAGE_NAME):$(OPENJDK25_VERSION) --target withtools .

docker_verify: ## check each built image runs the Java version its base image pins
	docker run --rm $(BASE_IMAGE_NAME):$(OPENJDK17_VERSION) java -version 2>&1 | grep -F '"$(call temurin_java_version,$(BASE_IMAGE_OPENJDK17))"'
	docker run --rm $(BASE_IMAGE_NAME):$(OPENJDK25_VERSION) java -version 2>&1 | grep -F '"$(call temurin_java_version,$(BASE_IMAGE_OPENJDK25))"'
	docker run --rm $(WITHTOOLS_IMAGE_NAME):$(OPENJDK17_VERSION) java -version 2>&1 | grep -F '"$(call temurin_java_version,$(BASE_IMAGE_OPENJDK17))"'
	docker run --rm $(WITHTOOLS_IMAGE_NAME):$(OPENJDK25_VERSION) java -version 2>&1 | grep -F '"$(call temurin_java_version,$(BASE_IMAGE_OPENJDK25))"'

docker_scout_install: ## install the pinned Docker Scout CLI plugin
	mkdir -p $(HOME)/.docker/cli-plugins
	curl -fsSL -o /tmp/docker-scout.tar.gz https://github.com/docker/scout-cli/releases/download/v$(DOCKER_SCOUT_VERSION)/docker-scout_$(DOCKER_SCOUT_VERSION)_linux_amd64.tar.gz
	echo "$(DOCKER_SCOUT_SHA256)  /tmp/docker-scout.tar.gz" | sha256sum -c -
	tar -xzf /tmp/docker-scout.tar.gz -C $(HOME)/.docker/cli-plugins docker-scout
	chmod +x $(HOME)/.docker/cli-plugins/docker-scout
	docker scout version

docker_scan: docker_scout_install ## scan docker images using Docker Scout (DOCKER_USER and DOCKER_PASS mandatory)
	@echo "$(DOCKER_PASS)" | docker login -u "$(DOCKER_USER)" --password-stdin
	docker scout quickview $(BASE_IMAGE_NAME):$(OPENJDK17_VERSION)
	docker scout quickview $(BASE_IMAGE_NAME):$(OPENJDK25_VERSION)
	docker scout quickview $(WITHTOOLS_IMAGE_NAME):$(OPENJDK17_VERSION)
	docker scout quickview $(WITHTOOLS_IMAGE_NAME):$(OPENJDK25_VERSION)


.PHONY: push-docker-image
push-docker-image: ## push the docker image to the registry (DOCKER_USER and DOCKER_PASS mandatory)
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS) &&\
	docker push $(BASE_IMAGE_NAME):$(OPENJDK17_VERSION)
	docker push $(BASE_IMAGE_NAME):$(OPENJDK25_VERSION)
	docker push $(WITHTOOLS_IMAGE_NAME):$(OPENJDK17_VERSION)
	docker push $(WITHTOOLS_IMAGE_NAME):$(OPENJDK25_VERSION)

.PHONY: push-latest-docker-image
push-latest-docker-image: ## push the docker image with the "latest" tag to the registry (DOCKER_USER and DOCKER_PASS mandatory)
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS) &&\
	docker tag $(BASE_IMAGE_NAME):$(OPENJDK25_VERSION) $(BASE_IMAGE_NAME):latest &&\
	docker tag $(WITHTOOLS_IMAGE_NAME):$(OPENJDK25_VERSION) $(WITHTOOLS_IMAGE_NAME):latest &&\
	docker push $(BASE_IMAGE_NAME):latest &&\
	docker push $(WITHTOOLS_IMAGE_NAME):latest

.PHONY: help
help:
	@echo "make help"
	@echo "\n"
	@grep -E '^[a-zA-Z_/%\-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo "\n"
