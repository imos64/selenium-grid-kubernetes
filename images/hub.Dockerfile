FROM docker.io/selenium/hub@sha256:178c2a330deb5c674c74ca63028737954106372ff66785244c16dfd66276654e
# pip is build tooling; removing it also removes its vulnerable vendored libraries.
# The hub uses the preinstalled supervisor/runtime packages and installs nothing at startup.
RUN /home/seluser/venv/bin/python3 -m pip uninstall --yes pip
ARG SOURCE_REVISION
LABEL org.opencontainers.image.source="https://github.com/imos64/selenium-grid-kubernetes" \
      org.opencontainers.image.revision="${SOURCE_REVISION}" \
      org.opencontainers.image.version="4.49.0-20260909-local.1" \
      org.opencontainers.image.base.name="docker.io/selenium/hub@sha256:178c2a330deb5c674c74ca63028737954106372ff66785244c16dfd66276654e"
USER 1200:1201
