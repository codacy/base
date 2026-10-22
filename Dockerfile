ARG base_image
FROM ${base_image} as base

LABEL maintainer="Codacy Team <code@codacy.com>"

RUN \
  apt-get -y update && \
  apt-get -y install software-properties-common && \
  add-apt-repository -y ppa:git-core/ppa && \
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

# CVE-2026-91403: block the compromised eMudhra intermediate CAs until the base image ships a fixed JRE.
# JDK 8 reads blacklisted.certs, newer JDKs read blocked.certs. Remove once the base images are bumped to a fixed JRE.
RUN \
  blocklist=$(find "${JAVA_HOME:?}/lib/security" "${JAVA_HOME}/jre/lib/security" -maxdepth 1 \( -name blocked.certs -o -name blacklisted.certs \) 2>/dev/null | head -n 1) && \
  test -n "$blocklist" && \
  printf '\n# CVE-2026-91403 eMudhra compromised intermediate CAs\n%s\n' \
    42C4ACCD12C4F59597925E1A08A7A90102608543809308D50EC427E118BA1493 \
    45A883F349AEDFD5F3A649B5498FFB121712BA8B448F3F2A91DBC5A766FCDDBE \
    98B896625C0C230ADEEC3EB2CF6AAD5001ECF9156A68644E82374CE5833BC25B \
    5F1DED4DD590AF74631290CF073B122A2AAC6A1FA479778A0BD43579BD832699 \
    E7568FE6E12331F4FD7DE61DA4C7559D0F8EB192A218D4741A3BA75184333838 \
    579480AEA166290BD3C643589E795FC0D0E54E86505D180F1DFF99EFD3199512 \
    0164D7CEAE5BB909C272AF151FF44B1177AE9B47D9424B94F1D9558C30934D19 \
    62B7F9868263F72F6911FC78CEAF72C1979158B7368BF648683BB2AA39B02E72 \
    CB6E15165AC802E9B3F993F16C25D41F4E81C21EBDE71AE1B012AC00BF9C7C3F \
    7485B51C0ED192878FA1D2F948FB529AE1842CC5086C4B67F7BE5B2039DE9489 \
    432EC25F0D28DE9006D97BF752F17BBB2CD41F669933FCB072D9A1148D0261F3 \
    FD9D5C2DBBD4995AB69B8D50C439D9527B00529199C2FD01B2174EB58F07021F \
    9E39DE2881273ACC225A149C72BA3E0F51424963669AB633EE1DC7DF5DB067B4 \
    A496E23AC0CAB8155FC9B117B97EAE368EFCBB9041AEC8804D5A308D2D01C2D8 \
    4B2460A466F95FD40113BCDCCA2CEB29B3B093921DE45474DA7DF48874C630B1 \
    84112972B8E59D14560AE7E7119654474AAD119990CF3722BFC1E3B91615E1FD \
    >> "$blocklist" && \
  grep -c 42C4ACCD12C4F59597925E1A08A7A90102608543809308D50EC427E118BA1493 "$blocklist"

# Git and SSH Configs
RUN \
  echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
  git config --global core.quotepath false && \
  git config --global core.packedGitLimit 512m && \
  git config --global core.packedGitWindowSize 512m && \
  git config --global pack.deltaCacheSize 2047m && \
  git config --global pack.packSizeLimit 2047m && \
  git config --global pack.windowMemory 2047m

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
