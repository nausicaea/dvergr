FROM docker.io/library/eclipse-temurin:21-jre-alpine@sha256:3f716d52e4045433e94a28d029c93d3c23179822a5d40b1c82b63aedd67c5081
VOLUME ["/var/lib/minecraft/.cache", "/var/lib/minecraft/universe"]
EXPOSE 25565/tcp
ARG MINECRAFT_VERSION=1.21.1
ARG MINECRAFT_SERVER_ID=minecraft
ENV MINECRAFT_SERVER_ID=${MINECRAFT_SERVER_ID}
ENV JAVA_INITIAL_MEM=256m
ENV JAVA_MAX_MEM=2g

ADD --checksum=sha256:c3ad3e23eee860e5185c594e7cb280e4fabe7e766a83945381d9a99c64855c5b https://quiltmc.org/api/v1/download-latest-installer/java-universal /tmp/quilt-installer.jar
RUN set -xe; \
    addgroup -S minecraft; \
    adduser -S -G minecraft -h /var/lib/minecraft -g "Minecraft Server" -s /bin/sh minecraft; \
    java -jar /tmp/quilt-installer.jar install server ${MINECRAFT_VERSION} --download-server --install-dir=/usr/local/lib/minecraft; \
    rm /tmp/quilt-installer.jar

WORKDIR /var/lib/minecraft
COPY quilt-server-launcher.properties quilt-server-launcher.properties
COPY eula.txt eula.txt
RUN set -xe; \
    java -jar /usr/local/lib/minecraft/quilt-server-launch.jar --initSettings; \
    chown -R minecraft:minecraft .
COPY --chmod=0755 docker-entrypoint.sh /bin/docker-entrypoint

USER minecraft:minecraft
ENTRYPOINT ["/bin/docker-entrypoint"]
