# Rebuild the existing helper sources with the patched compiler.
FROM golang:1.27.3-bookworm@sha256:dc0963f32053e4bc451d24d87e3892d42d01021b61f093e98eb95c0352bb84b0 AS helpers
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

FROM docker.io/selenium/hub@sha256:9c8f6814537cdbd9d75e7c6efad52518fd3a7aade76cc760aaeeaf85c7ecb888
# pip is build tooling; removing it also removes its vulnerable vendored libraries.
# The hub uses the preinstalled supervisor/runtime packages and installs nothing at startup.
RUN /home/seluser/venv/bin/python3 -m pip uninstall --yes pip
USER root
RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*
COPY --from=helpers --chown=1200:1201 /out/envsubst /usr/local/bin/envsubst
COPY --from=helpers --chown=1200:1201 /out/selenium-grid-exporter /opt/bin/selenium-grid-exporter
ARG SOURCE_REVISION
LABEL org.opencontainers.image.source="https://github.com/imos64/selenium-grid-kubernetes" \
      org.opencontainers.image.revision="${SOURCE_REVISION}" \
      org.opencontainers.image.version="4.54.0-20261124-local.1" \
      org.opencontainers.image.base.name="docker.io/selenium/hub@sha256:9c8f6814537cdbd9d75e7c6efad52518fd3a7aade76cc760aaeeaf85c7ecb888"
USER 1200:1201
