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

# Right half as a glasses pad: Ben Vallack's 4 Key BLE pad firmware (a custom
# GATT service, not a keyboard) with the Sweep's pins. See blepad/README.md.
# Needs a local 4key-macropad checkout; mode is debug (Ben's daily build) or release.
blepad-build mode="debug" src=env("BLEPAD_SRC", home_directory() / "Code/glasses/4key-macropad"):
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ mode }}" in debug|release) ;; *) echo "mode must be debug or release" >&2; exit 2 ;; esac
    if [[ ! -f "{{ src }}/ble-firmware/src/main.c" ]]; then
      echo "no 4key-macropad checkout at {{ src }} (set BLEPAD_SRC)" >&2
      exit 1
    fi
    # Copy into the ignored build dir: the container only mounts this repo
    dst="{{ justfile_dir() }}/.build/blepad-src"
    rm -rf "$dst"
    mkdir -p "{{ justfile_dir() }}/.build"
    cp -R "{{ src }}/ble-firmware" "$dst"
    # The firmware takes key codes 1-5; widen to the overlay's 8 keys
    sed -i.orig 's/evt->code > INPUT_KEY_5)/evt->code > INPUT_KEY_8)/' "$dst/src/main.c"
    if ! grep -q 'INPUT_KEY_8)' "$dst/src/main.c"; then
      echo "key range edit did not apply; 4key-macropad changed" >&2
      exit 1
    fi
    printf 'blepad source: 4key-macropad@%s, keys 1-8\n' "$(git -C "{{ src }}" rev-parse --short HEAD)"
    just devc-exec in-devc blepad-build "{{ mode }}"
