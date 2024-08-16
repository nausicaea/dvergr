# syntax=docker/dockerfile:1

FROM docker.io/library/eclipse-temurin:21-jre-alpine@sha256:3f716d52e4045433e94a28d029c93d3c23179822a5d40b1c82b63aedd67c5081
VOLUME ["/var/lib/minecraft/.cache", "/var/lib/minecraft/audioplayer_uploads", "/var/lib/minecraft/backups", "/var/lib/minecraft/config", "/var/lib/minecraft/logs", "/var/lib/minecraft/universe"]
EXPOSE 25565/tcp 24454/udp
ARG MINECRAFT_VERSION=1.21.1
ENV MINECRAFT_SERVER_ID=minecraft
ENV JAVA_INITIAL_MEM=256M
ENV JAVA_MAX_MEM=2G
ENV OTEL_JAVAAGENT_DEBUG=false
ENV OTEL_EXPORTER=otlp
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://otel_collector:4317

ADD --link --checksum=sha256:c3ad3e23eee860e5185c594e7cb280e4fabe7e766a83945381d9a99c64855c5b https://quiltmc.org/api/v1/download-latest-installer/java-universal /tmp/quilt-installer.jar
ADD --link --checksum=sha256:e77f7f3e2f2601a288bd8cb9deb7e2f9578034344e761587f51f03e097ae02ce --chmod=0644 https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v1.33.5/opentelemetry-javaagent.jar /usr/local/lib/
ADD --link --checksum=sha256:93dd11528af33d51086e4340720341a3a8b978771e1750f3f2dd6903e854f1de --chmod=0644 https://repo1.maven.org/maven2/io/opentelemetry/instrumentation/opentelemetry-log4j-appender-2.17/2.6.0-alpha/opentelemetry-log4j-appender-2.17-2.6.0-alpha.jar /usr/local/lib/
ADD --link --checksum=sha256:7d3cd0cf6bdcb2f8372494a60ebf76b16770067c26726d47ca8aa639ca6a7d1a --chmod=0644 https://repo1.maven.org/maven2/io/opentelemetry/opentelemetry-api/1.40.0/opentelemetry-api-1.40.0.jar /usr/local/lib/
ADD --link --checksum=sha256:407824792c3e13a3515fd22351542089e733c70267ddac015d707efe757ec92b --chmod=0644 https://repo1.maven.org/maven2/io/opentelemetry/opentelemetry-api-incubator/1.40.0-alpha/opentelemetry-api-incubator-1.40.0-alpha.jar /usr/local/lib/
ADD --link --checksum=sha256:5c0452a133f76872bed5bbd685c7f9515b15d43db8a46b2f8ca8409a390bf424 --chmod=0644 https://repo1.maven.org/maven2/io/opentelemetry/opentelemetry-context/1.40.0/opentelemetry-context-1.40.0.jar /usr/local/lib/
ADD --link --checksum=sha256:818dd23b5b9415a99bf5395ace86ca36feb6321e11ad70ef9ceb1369d87d963f --chmod=0644 https://repo1.maven.org/maven2/io/opentelemetry/instrumentation/opentelemetry-instrumentation-api/2.6.0/opentelemetry-instrumentation-api-2.6.0.jar /usr/local/lib/
ADD --link --checksum=sha256:831d671bafa8ed83ae3b9a47f1066aaae533567388459555db82ff3a9e986cfe --chmod=0644 https://repo1.maven.org/maven2/io/opentelemetry/instrumentation/opentelemetry-instrumentation-api-incubator/2.6.0-alpha/opentelemetry-instrumentation-api-incubator-2.6.0-alpha.jar /usr/local/lib/
ADD --link --checksum=sha256:745a86a75ecb5e03f464f05ea2dc76e0f04d07273c5509fa74f393bff9b222b7 --chmod=0644 https://repo1.maven.org/maven2/io/opentelemetry/semconv/opentelemetry-semconv/1.25.0-alpha/opentelemetry-semconv-1.25.0-alpha.jar /usr/local/lib/
RUN set -xe; \
    addgroup -S minecraft; \
    adduser -S -G minecraft -h /var/lib/minecraft -g "Minecraft Server" -s /bin/sh minecraft; \
    java \
        -jar /tmp/quilt-installer.jar \
        install server ${MINECRAFT_VERSION} \
        --download-server \
        --install-dir=/usr/local/lib/minecraft; \
    rm /tmp/quilt-installer.jar

WORKDIR /var/lib/minecraft
COPY quilt-server-launcher.properties eula.txt ./
COPY log4j2.xml server.properties opentelemetry.properties ./
COPY ops.json whitelist.json banned-ips.json banned-players.json ./
RUN set -xe; \
    mkdir -p .cache audioplayer_uploads backups logs universe; \
    java \
        -jar /usr/local/lib/minecraft/quilt-server-launch.jar \
        --initSettings; \
    chown -R minecraft:minecraft .
COPY --chmod=0755 docker-entrypoint.sh /bin/docker-entrypoint

USER minecraft:minecraft
ENTRYPOINT ["/bin/docker-entrypoint"]
