# Defaults to the published image so the fixture works standalone; CI overrides
# it with an image built from this checkout, so changes to devbase/Dockerfile
# are covered before they are published.
ARG DEVBASE_IMAGE=ghcr.io/komadori-dev/devbase:latest
FROM ${DEVBASE_IMAGE}

RUN apk add --no-cache nodejs npm

WORKDIR /workspace/node-example
