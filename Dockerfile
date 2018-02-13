FROM develar/java
MAINTAINER Rafael Cortês <rafael@codacy.com>

ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LC_ALL C.UTF-8

RUN \
  echo "http://dl-cdn.alpinelinux.org/alpine/v3.5/main" >> /etc/apk/repositories && \
  echo "http://dl-cdn.alpinelinux.org/alpine/v3.5/community" >> /etc/apk/repositories && \
  apk update && \
  apk add bash git=2.11.3-r0 openssh && \
  echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
  git config --global core.quotepath false && \
  git config --global core.packedGitLimit 512m && \
  git config --global core.packedGitWindowSize 512m && \
  git config --global pack.deltaCacheSize 2047m && \
  git config --global pack.packSizeLimit 2047m && \
  git config --global pack.windowMemory 2047m && \
  rm -rf /var/cache/apk/*

ENV TINI_VERSION v0.16.1
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
