set positional-arguments := true
set shell := ["bash", "-euco", "pipefail"]

alias b := build-all

mod draw ".just/draw.just"
mod flash ".just/flash.just"
mod in-devc ".just/in-devc.just"

# Open picker with "jj" alias
[no-cd]
_default:
    @just --list --list-submodules


devc-exec +recipe:
    #!/usr/bin/env bash
    if [ -z "${container}" ]; then
      printf "NOT in devc\n"
      just devc-up
      devcontainer exec \
        --workspace-folder "{{ justfile_directory() }}" \
        --docker-path podman \
        --docker-compose-path podman-compose \
        -- just {{ recipe }}
    else
      printf "IN devc\n"
      just {{ recipe }}
    fi

devc-reset:
    podman volume rm zmk-repo-home --force

devc-build:
    devcontainer build \
      --workspace-folder "{{ justfile_directory() }}" \
      --docker-path podman \
      --docker-compose-path podman-compose \
      --remove-existing-container

devc-up:
    devcontainer up \
      --workspace-folder "{{ justfile_directory() }}" \
      --docker-path podman \
      --docker-compose-path podman-compose \
      --remove-existing-container
    #   --skip-post-attach
    podman ps --last 1

mkdirs:
    @just devc-exec in-devc mkdirs

hard-rmdirs:
    @just devc-exec in-devc hard-rmdirs 

# initialize west
west-init:
    @just devc-exec in-devc west-init

# you might need to run this multiple times after "init"
west-update:
    @just devc-exec in-devc west-update

# update west
update:
    @just devc-exec in-devc update

# Builds with ZMK Studio
build-firmware:
    @just devc-exec in-devc build-firmware

generic-build +args:
    @just devc-exec in-devc generic-build  {{ args }}

# https://zmk.dev/docs/troubleshooting/connection-issues#reset-split-keyboard-procedure
build-settings-reset-firmware:
    @just devc-exec in-devc build-settings-reset-firmware

build-all: build-firmware build-settings-reset-firmware

fmt-just:
    @just --fmt --unstable
    # cd .just/ && just --fmt --unstable
