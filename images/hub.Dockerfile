# Rebuild the existing helper sources with the patched compiler.
FROM golang:1.27.4-bookworm@sha256:ce59b41415e2524ae99926fe1f37ce48ba8c194dcbd2a56a65436cdcefa2bd34 AS helpers
ENV GOTOOLCHAIN=local GOMAXPROCS=2 CGO_ENABLED=0
ADD --checksum=sha256:e90a56fafa8f119a1282a734fa3e650e3cdb2bf5bc3d3c4154c42db2dc2a7408 https://codeload.github.com/SeleniumHQ/docker-selenium/tar.gz/b8c2fda186f98ce421c7df5f93e34034544c8e40 /tmp/selenium.tar.gz
ADD --checksum=sha256:0aada33c43b514ec812528ed8de5eea549868ce85b5bea7ec015f2bd8b7339ca https://codeload.github.com/a8m/envsubst/tar.gz/bf6a99e3e2525ab75aca34d66c827eabbefbc236 /tmp/envsubst.tar.gz
RUN mkdir -p /src/exporter /src/envsubst /out \
    && tar -xzf /tmp/selenium.tar.gz -C /src/exporter --strip-components=3 docker-selenium-b8c2fda186f98ce421c7df5f93e34034544c8e40/.monitoring/exporter \
    && tar -xzf /tmp/envsubst.tar.gz -C /src/envsubst --strip-components=1
WORKDIR /src/exporter
RUN go mod download && go test -mod=readonly -p 2 ./... \
    && go build -mod=readonly -p 2 -ldflags="-s -w" -o /out/selenium-grid-exporter .
WORKDIR /src/envsubst
COPY images/envsubst-literal-output.patch /tmp/envsubst.patch
RUN git apply --check /tmp/envsubst.patch && git apply /tmp/envsubst.patch
RUN go test -mod=readonly -p 2 ./... \
    && go build -mod=readonly -p 2 -o /out/envsubst ./cmd/envsubst

WORKDIR /src/pebble
ADD --checksum=sha256:b697b87fc5412ecffdc73835fd7e396c27dc9a44e4069257686433d92203354b https://codeload.github.com/canonical/pebble/tar.gz/73bb6ea76d1b253020f9039067075ea3b1ec5175 /tmp/pebble.tar.gz
RUN tar -xzf /tmp/pebble.tar.gz --strip-components=1 \
    && printf '1.33.3' > cmd/VERSION \
    && go get golang.org/x/net@v0.62.0 \
    && go build -mod=readonly -p 2 -o /out/pebble ./cmd/pebble

FROM docker.io/selenium/hub@sha256:9c8f6814537cdbd9d75e7c6efad52518fd3a7aade76cc760aaeeaf85c7ecb888
# pip is build tooling; removing it also removes its vulnerable vendored libraries.
# The hub uses the preinstalled supervisor/runtime packages and installs nothing at startup.
RUN /home/seluser/venv/bin/python3 -m pip uninstall --yes pip
USER root
RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*
# The upstream OpenTelemetry classpath points to a separate Guava Android jar.
ARG GUAVA_CACHE=/external_jars/https/repo1.maven.org/maven2/com/google/guava/guava
ADD --chmod=0644 --checksum=sha256:b949fe975a32421c1a2633c07a4f1578b462f2f467668aa0a4023c5ff7c4a808 https://repo.maven.apache.org/maven2/com/google/guava/guava/33.7.2-android/guava-33.7.2-android.jar ${GUAVA_CACHE}/33.7.2-android/guava-33.7.2-android.jar
RUN test -f "${GUAVA_CACHE}/33.6.0-android/guava-33.6.0-android.jar" \
    && grep -q '33.6.0-android/guava-33.6.0-android.jar' /external_jars/.classpath.txt \
    && sed -i 's|33.6.0-android/guava-33.6.0-android.jar|33.7.2-android/guava-33.7.2-android.jar|g' /external_jars/.classpath.txt \
    && rm -r "${GUAVA_CACHE}/33.6.0-android"
COPY --from=helpers /out/pebble /usr/bin/pebble
COPY --from=helpers --chown=1200:1201 /out/envsubst /usr/local/bin/envsubst
COPY --from=helpers --chown=1200:1201 /out/selenium-grid-exporter /opt/bin/selenium-grid-exporter
ARG SOURCE_REVISION
LABEL org.opencontainers.image.source="https://github.com/imos64/selenium-grid-kubernetes" \
      org.opencontainers.image.revision="${SOURCE_REVISION}" \
      org.opencontainers.image.version="4.54.0-20261124-local.1" \
      org.opencontainers.image.base.name="docker.io/selenium/hub@sha256:9c8f6814537cdbd9d75e7c6efad52518fd3a7aade76cc760aaeeaf85c7ecb888"
USER 1200:1201
