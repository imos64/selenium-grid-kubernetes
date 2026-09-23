FROM docker.io/selenium/node-chromium@sha256:0a2e549fcd4f52393b1390b5282e09a8cefc68d6a8790de55fdf855b26c557cd
RUN /home/seluser/venv/bin/python3 -m pip uninstall --yes pip
# The local profile disables uploads/video. Remove the unused vulnerable uploader binary.
USER root
RUN rm /usr/local/bin/rclone
ARG SOURCE_REVISION
LABEL org.opencontainers.image.source="https://github.com/imos64/selenium-grid-kubernetes" \
      org.opencontainers.image.revision="${SOURCE_REVISION}" \
      org.opencontainers.image.version="4.49.0-20260909-local.1" \
      org.opencontainers.image.base.name="docker.io/selenium/node-chromium@sha256:0a2e549fcd4f52393b1390b5282e09a8cefc68d6a8790de55fdf855b26c557cd"
USER 1200:1201
