FROM ubuntu:20.04

ENV JAVA_HOME /opt/java/openjdk
ENV PATH $JAVA_HOME/bin:$PATH
ENV JAVA_VERSION jdk8u362-b09
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata curl wget ca-certificates fontconfig locales \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*


RUN wget -O /tmp/openjdk.tar.gz  'https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u362-b09/OpenJDK8U-jre_x64_linux_hotspot_8u362b09.tar.gz' \
    && echo "c8c4e180f915fc7c163240bf363dcdf2b481cd2723fabfc3d08ccf12e049611f */tmp/openjdk.tar.gz" | sha256sum -c - \
    && mkdir -p "$JAVA_HOME" \
    && tar xvf /tmp/openjdk.tar.gz -C "$JAVA_HOME" --strip-components 1 --no-same-owner \
    && rm -f /tmp/openjdk.tar.gz ${JAVA_HOME}/src.zip \
    && find "$JAVA_HOME/lib" -name '*.so' -exec dirname '{}' ';' | sort -u > /etc/ld.so.conf.d/docker-openjdk.conf \
    && ldconfig \
    && java -version
