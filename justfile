set positional-arguments := true
set shell := ["bash", "-euco", "pipefail"]

# config := absolute_path('config')

alias b := build

mod draw ".just/draw.just"
mod in-devc ".just/in-devc.just"

# Open picker with "jj" alias
[no-cd]
_default:
    @just --list

# recipe context +collection:
#     #!/usr/bin/env bash
#     if [ '{{ collection }}' != '' ]; then
#       for item in {{ collection }}; do
#         echo just dynamic-{{ context }} $item
#       done
#     else
#       echo "No collection to process with dynamic-{{ context }}"
#     fi

devc-exec +recipe: devc-up
    devcontainer exec \
      --workspace-folder "{{ justfile_directory() }}" \
      --docker-path podman \
      -- just {{ recipe }}

devc-build:
    devcontainer build \
      --workspace-folder "{{ justfile_directory() }}" \
      --docker-path podman \
      --remove-existing-container

devc-up:
    devcontainer up \
      --workspace-folder "{{ justfile_directory() }}" \
      --docker-path podman \
      --remove-existing-container \
      --skip-post-attach
    podman ps --last 1

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

# https://zmk.dev/docs/troubleshooting/connection-issues#reset-split-keyboard-procedure
build-settings-reset-firmware:
    @just devc-exec in-devc build-settings-reset-firmware

build: build-firmware build-settings-reset-firmware

fmt-just:
    @just --fmt --unstable
    # cd .just/ && just --fmt --unstable
