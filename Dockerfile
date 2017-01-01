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

# Docker 1.12.x binary
RUN \
    wget https://get.docker.com/builds/Linux/x86_64/docker-1.12.5.tgz && \
    tar -xvf docker-1.12.5.tgz --strip-components 1 docker/docker && \
    mv docker /usr/bin/docker-1.12.5 && \
    chmod +x /usr/bin/docker-1.12.5 && \
    rm -rf docker-1.12.5.tgz
