set positional-arguments := true
set shell := ["bash", "-euco", "pipefail"]

# alias b := build-all

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
        --workspace-folder "{{ justfile_dir() }}" \
        --docker-path podman \
        --docker-compose-path podman-compose \
        -- bash -lc 'just "$@"' _ {{ recipe }}
    else
      printf "IN devc\n"
      bash -c 'just "$@"' _ {{ recipe }}
    fi

devc-reset:
    podman volume rm zmk-repo-home --force

devc-build:
    devcontainer build \
      --workspace-folder "{{ justfile_dir() }}" \
      --docker-path podman \
      --docker-compose-path podman-compose

devc-up:
    devcontainer up \
      --workspace-folder "{{ justfile_dir() }}" \
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

generic-build board shield snippet="" cmake_args="" artifact_name="" pristine="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -z "${container:-}" ]; then
      just devc-up
      devcontainer exec \
        --workspace-folder "{{ justfile_dir() }}" \
        --docker-path podman \
        --docker-compose-path podman-compose \
        -- bash -lc 'just in-devc generic-build "$@"' _ \
        "{{board}}" "{{shield}}" "{{snippet}}" "{{cmake_args}}" "{{artifact_name}}" "{{pristine}}"
    else
      just in-devc generic-build "{{board}}" "{{shield}}" "{{snippet}}" "{{cmake_args}}" "{{artifact_name}}" "{{pristine}}"
    fi

fmt-just:
    @just --fmt --unstable
    # cd .just/ && just --fmt --unstable
