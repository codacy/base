BASE_IMAGE_NAME=codacy/base
WITHTOOLS_IMAGE_NAME=codacy/withtools

VERSION?=$(shell cat .version || echo dev)
OPENJDK17_VERSION?=jre17-$(VERSION)
OPENJDK25_VERSION?=jre25-$(VERSION)
CORRETTO17_VERSION=17.0.21.1.2
CORRETTO25_VERSION=25.0.5.1.2
BASE_IMAGE_OPENJDK17=amazoncorretto:17.0.21-al2023-headless@sha256:8011b08e892b5c537f7fa91b8eec52356f4744d67fdb0843b9c7168e4575cf54
BASE_IMAGE_OPENJDK25=amazoncorretto:25.0.5-al2023-headless@sha256:411162c79452155a12b81211dd0abeeef380f6903e4d0468c06c15c4908cfc9f
DOCKER_SCOUT_VERSION=1.29.0
DOCKER_SCOUT_SHA256=9157cdc9372b478a8cd51dd53f5e9c74a7e34056ea291c65520bf76016fa72f4

all: docker_build ## produce the docker image

docker_build: ## build the docker image
	docker build --build-arg base_image=$(BASE_IMAGE_OPENJDK17) --no-cache -t $(BASE_IMAGE_NAME):$(OPENJDK17_VERSION) --target base .
	docker build --build-arg base_image=$(BASE_IMAGE_OPENJDK25) --no-cache -t $(BASE_IMAGE_NAME):$(OPENJDK25_VERSION) --target base .

	docker build --build-arg base_image=$(BASE_IMAGE_OPENJDK17) --no-cache -t $(WITHTOOLS_IMAGE_NAME):$(OPENJDK17_VERSION) --target withtools .
	docker build --build-arg base_image=$(BASE_IMAGE_OPENJDK25) --no-cache -t $(WITHTOOLS_IMAGE_NAME):$(OPENJDK25_VERSION) --target withtools .

docker_verify: ## check each built image runs the pinned Corretto build and ships the tools services rely on
	docker run --rm $(BASE_IMAGE_NAME):$(OPENJDK17_VERSION) java -version 2>&1 | grep -F 'Corretto-$(CORRETTO17_VERSION)'
	docker run --rm $(BASE_IMAGE_NAME):$(OPENJDK25_VERSION) java -version 2>&1 | grep -F 'Corretto-$(CORRETTO25_VERSION)'
	docker run --rm $(WITHTOOLS_IMAGE_NAME):$(OPENJDK17_VERSION) java -version 2>&1 | grep -F 'Corretto-$(CORRETTO17_VERSION)'
	docker run --rm $(WITHTOOLS_IMAGE_NAME):$(OPENJDK25_VERSION) java -version 2>&1 | grep -F 'Corretto-$(CORRETTO25_VERSION)'
	for image in $(BASE_IMAGE_NAME):$(OPENJDK17_VERSION) $(BASE_IMAGE_NAME):$(OPENJDK25_VERSION) $(WITHTOOLS_IMAGE_NAME):$(OPENJDK17_VERSION) $(WITHTOOLS_IMAGE_NAME):$(OPENJDK25_VERSION); do \
	  docker run --rm $$image bash -c 'set -e; git --version; for tool in ssh-agent ssh-add unzip useradd; do command -v $$tool; done; /tini --version; ssh -G example.com | grep -x "stricthostkeychecking false"' || exit 1; \
	done

docker_scout_install: ## install the pinned Docker Scout CLI plugin
	set -e; \
	plugins="$${DOCKER_CONFIG:-$$HOME/.docker}/cli-plugins"; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	curl -fsSL -o "$$tmp/docker-scout.tar.gz" https://github.com/docker/scout-cli/releases/download/v$(DOCKER_SCOUT_VERSION)/docker-scout_$(DOCKER_SCOUT_VERSION)_linux_amd64.tar.gz; \
	echo "$(DOCKER_SCOUT_SHA256)  $$tmp/docker-scout.tar.gz" | sha256sum -c -; \
	mkdir -p "$$plugins"; \
	tar -xzf "$$tmp/docker-scout.tar.gz" -C "$$plugins" docker-scout; \
	chmod +x "$$plugins/docker-scout"
	docker scout version

docker_scan: docker_scout_install ## scan docker images using Docker Scout, failing on fixable critical or high OS package CVEs (DOCKER_USER and DOCKER_PASS mandatory)
	@test -n "$$DOCKER_USER" && test -n "$$DOCKER_PASS" || { echo "DOCKER_USER and DOCKER_PASS are required"; exit 1; }
	@printf '%s' "$$DOCKER_PASS" | docker login -u "$$DOCKER_USER" --password-stdin
	for image in $(BASE_IMAGE_NAME):$(OPENJDK17_VERSION) $(BASE_IMAGE_NAME):$(OPENJDK25_VERSION) $(WITHTOOLS_IMAGE_NAME):$(OPENJDK17_VERSION) $(WITHTOOLS_IMAGE_NAME):$(OPENJDK25_VERSION); do \
	  docker scout quickview $$image && \
	  docker scout cves --only-fixed --only-severity critical,high --only-package-type rpm --exit-code $$image || exit 1; \
	done


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
