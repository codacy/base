FROM    rtfpessoa/ubuntu-jdk8:latest
MAINTAINER  Johann Egger <johann@codacy.com>

ENV LANG en_US.UTF-8 
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install and setup project dependencies
RUN \
  locale-gen en_US.UTF-8 && \
  echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
  git config --global core.quotepath false && \
  git config --global core.packedGitLimit 512m && \
  git config --global core.packedGitWindowSize 512m && \
  git config --global pack.deltaCacheSize 2047m && \
  git config --global pack.packSizeLimit 2047m && \
  git config --global pack.windowMemory 2047m

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
