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

# Docker binaries
RUN \
  wget https://get.docker.com/builds/Linux/x86_64/docker-1.10.3 && \
  wget https://get.docker.com/builds/Linux/x86_64/docker-1.7.0 && \
  wget https://get.docker.com/builds/Linux/x86_64/docker-1.9.1 && \
  mv docker-1.10.3 /usr/bin/docker-1.10.3 && \
  mv docker-1.7.0 /usr/bin/docker-1.7.0 && \
  mv docker-1.9.1 /usr/bin/docker-1.9.1 && \
  chmod +x /usr/bin/docker-1.10.3 && \
  chmod +x /usr/bin/docker-1.9.1 && \
  chmod +x /usr/bin/docker-1.7.0
