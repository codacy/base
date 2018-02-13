FROM rtfpessoa/ubuntu-jdk8:latest
MAINTAINER Rodrigo Fernandes <rodrigo@codacy.com>

RUN locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Git and SSH Configs
RUN \
  echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
  git config --global core.quotepath false && \
  git config --global core.packedGitLimit 512m && \
  git config --global core.packedGitWindowSize 512m && \
  git config --global pack.deltaCacheSize 2047m && \
  git config --global pack.packSizeLimit 2047m && \
  git config --global pack.windowMemory 2047m

# Docker 1.9.1 binary
RUN \
  wget https://get.docker.com/builds/Linux/x86_64/docker-1.9.1 && \
  mv docker-1.9.1 /usr/bin/docker-1.9.1 && \
  chmod +x /usr/bin/docker-1.9.1

# Docker 17.09.0 binary
RUN \
    DOCKER_VERSION="docker-17.09.0-ce" && \
    wget https://download.docker.com/linux/static/stable/x86_64/$DOCKER_VERSION.tgz && \
    tar -xvf $DOCKER_VERSION.tgz --strip-components 1 docker/docker && \
    rm -rf $DOCKER_VERSION.tgz && \
    mv docker /usr/bin/$DOCKER_VERSION && \
    chmod +x /usr/bin/$DOCKER_VERSION

ENV TINI_VERSION v0.16.1
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
