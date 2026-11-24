ARG base_image
FROM ${base_image} as base

LABEL maintainer="Codacy Team <code@codacy.com>"

RUN \
  dnf -y upgrade --releasever=latest --exclude="java-*-amazon-corretto*" && \
  dnf -y install git-core openssh-clients shadow-utils unzip && \
  dnf clean all && \
  rm -rf /var/cache/dnf && \
  rm -rf /tmp/*

# Git and SSH Configs
RUN \
  mkdir -p /etc/ssh/ssh_config.d && \
  echo "StrictHostKeyChecking no" > /etc/ssh/ssh_config.d/00-codacy.conf && \
  git config --global core.quotepath false && \
  git config --global core.packedGitLimit 512m && \
  git config --global core.packedGitWindowSize 512m && \
  git config --global pack.deltaCacheSize 2047m && \
  git config --global pack.packSizeLimit 2047m && \
  git config --global pack.windowMemory 2047m

ARG TINI_VERSION=v0.19.0
ARG TINI_SHA256=c5b0666b4cb676901f90dfcb37106783c5fe2077b04590973b885950611b30ee
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-amd64 /tini
RUN echo "${TINI_SHA256}  /tini" | sha256sum -c - && chmod +x /tini

FROM base as withtools

RUN \
  dnf -y install device-mapper-libs libtool-ltdl && \
  dnf clean all && \
  rm -rf /var/cache/dnf && \
  rm -rf /tmp/*
