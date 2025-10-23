ARG base_image
FROM ${base_image} as base

LABEL maintainer="Codacy Team <code@codacy.com>"

RUN \
  apt-get -y update && \
  apt-get -y install unzip git && \
  apt-get -y upgrade && \
  rm -rf /root/.cache && \
  apt-get purge -y $(apt-cache search '~c' | awk '{ print $2 }') && \
  apt-get -y autoremove && \
  apt-get -y autoclean && \
  apt-get -y clean all && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/apt && \
  rm -rf /tmp/*

# Git and SSH Configs
RUN \
  echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
  git config --global core.quotepath false && \
  git config --global core.packedGitLimit 512m && \
  git config --global core.packedGitWindowSize 512m && \
  git config --global pack.deltaCacheSize 2047m && \
  git config --global pack.packSizeLimit 2047m && \
  git config --global pack.windowMemory 2047m

# Docker 17.09.0 binary
# Used for cloud and enterprise before kubernetes in:
#  - https://bitbucket.org/qamine/worker-manager/src/a24392951fb84c3551a007cf8128eed2ada9e7e2/conf/reference.conf#lines-238
#  - https://bitbucket.org/qamine/codacy-doplicated/src/954dd8e7c9c28bdea0143682cc2fe21a0e878cdd/variables/conf.dockerversion.json#lines-5
RUN \
  DOCKER_VERSION="docker-17.09.0-ce" && \
  wget https://download.docker.com/linux/static/stable/x86_64/$DOCKER_VERSION.tgz && \
  tar -xvf $DOCKER_VERSION.tgz --strip-components 1 docker/docker && \
  rm -rf $DOCKER_VERSION.tgz && \
  mv docker /usr/bin/$DOCKER_VERSION && \
  chmod +x /usr/bin/$DOCKER_VERSION && \
  apt-get update && apt-get upgrade -y

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

FROM base as withtools

RUN \
  apt-get -y update && \
  apt-get -y install apparmor libdevmapper1.02.1 && \
  apt-get -y install libltdl-dev && \
  ln -s /lib/x86_64-linux-gnu/libdevmapper.so.1.02.1 /lib/x86_64-linux-gnu/libdevmapper.so.1.02 && \
  apt-get purge -y $(apt-cache search '~c' | awk '{ print $2 }') && \
  apt-get -y autoremove && \
  apt-get -y autoclean && \
  apt-get -y clean all && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/apt && \
  rm -rf /var/cache/oracle-jdk8-installer && \
  rm -rf /tmp/*
