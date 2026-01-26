# https://github.com/zmkfirmware/zmk
# https://github.com/zmkfirmware/zmk/blob/main/.devcontainer/Dockerfile

# FROM docker.io/zmkfirmware/zmk-dev-arm:4.1-branch
ARG BASE_IMAGE=docker.io/zmkfirmware/zmk-dev-arm
ARG BASE_TAG=3.5

# DO NOT INSTALL UV
# ARG UV_VERSION="0.9.25-trixie"
# FROM ghcr.io/astral-sh/uv:$UV_VERSION AS uv

FROM ${BASE_IMAGE}:${BASE_TAG}
#Username already set in the base image
ARG USERNAME=ubuntu
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# RUN groupmod --gid $USER_GID $USERNAME \
#   && usermod --uid $USER_UID --gid $USER_GID $USERNAME \
#   && chown -R $USER_UID:$USER_GID /home/$USERNAME

# RUN mkdir -p /home/$USERNAME/.local/bin \
# && mkdir -p /home/$USERNAME/.vscode-server

# RUN chown -R $USER_UID:$USER_GID /home/$USERNAME/.vscode-server

# RUN mkdir -p /home/$USERNAME/project && \
#   chown -R $USER_UID:$USER_GID /home/$USERNAME/project


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

# COPY --from=uv --chown=$USER_UID:$USER_GID /usr/local/bin/uv /usr/local/bin/uvx /usr/local/bin/

COPY .devcontainer/scripts/docker-build.sh /tmp/docker-build.sh
ARG TARGETPLATFORM
ARG JUST_VERSION=1.46.0
RUN TARGETPLATFORM=${TARGETPLATFORM} \
  JUST_VERSION=${JUST_VERSION} \
  bash /tmp/docker-build.sh \
  && rm /tmp/docker-build.sh

# RUN mkdir -p /workspace && \
#   chown -R $USER_UID:$USER_GID /workspace
WORKDIR /workspace/

USER 1000
