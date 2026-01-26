# https://github.com/zmkfirmware/zmk
# https://github.com/zmkfirmware/zmk/blob/main/.devcontainer/Dockerfile

# FROM docker.io/zmkfirmware/zmk-dev-arm:4.1-branch
ARG BASE_IMAGE=docker.io/zmkfirmware/zmk-dev-arm
ARG BASE_TAG=3.5

# DO NOT INSTALL UV

FROM ${BASE_IMAGE}:${BASE_TAG}

RUN : \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  --no-install-recommends \
  ripgrep \
  fd-find \
  fzf \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && :

COPY .devcontainer/scripts/docker-build.sh /tmp/docker-build.sh
ARG TARGETPLATFORM
ARG JUST_VERSION=1.46.0
RUN TARGETPLATFORM=${TARGETPLATFORM} \
  JUST_VERSION=${JUST_VERSION} \
  bash /tmp/docker-build.sh \
  && rm /tmp/docker-build.sh

WORKDIR /workspace/

USER 1000
