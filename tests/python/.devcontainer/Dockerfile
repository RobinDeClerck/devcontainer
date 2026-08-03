# Defaults to the published image so the fixture works standalone; CI overrides
# it with an image built from this checkout, so changes to devbase/Dockerfile
# are covered before they are published.
ARG DEVBASE_IMAGE=ghcr.io/komadori-dev/devbase:latest
FROM ${DEVBASE_IMAGE}

ENV PYTHONPATH=/workspace/python-example

RUN apk add --no-cache python3 py3-pip

WORKDIR /workspace/python-example