# https://github.com/zmkfirmware/zmk
# https://github.com/zmkfirmware/zmk/blob/main/.devcontainer/Dockerfile

# FROM docker.io/zmkfirmware/zmk-dev-arm:4.1-branch

FROM docker.io/zmkfirmware/zmk-dev-arm:3.5
#Username already set in the base image
ARG USERNAME=ubuntu
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupmod --gid $USER_GID $USERNAME \
  && usermod --uid $USER_UID --gid $USER_GID $USERNAME \
  && chown -R $USER_UID:$USER_GID /home/$USERNAME

RUN mkdir -p /home/$USERNAME/.local/bin
RUN mkdir -p /home/$USERNAME/.vscode-server
RUN chown -R $USER_UID:$USER_GID /home/$USERNAME/.vscode-server

RUN mkdir -p /home/$USERNAME/project && \
  chown -R $USER_UID:$USER_GID /home/$USERNAME/project


RUN : \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  --no-install-recommends \
  just \
  ripgrep \
  fd-find \
  fzf \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && :

RUN mkdir -p /workspace && \
  chown -R $USER_UID:$USER_GID /workspace
WORKDIR /workspace/

USER ubuntu
# ENV USER=$USERNAME

