set positional-arguments := true
set shell := ["bash", "-euco", "pipefail"]

config := absolute_path('config')
out := absolute_path('firmware')
build := absolute_path('.build')
result := absolute_path('result')
draw := absolute_path('draw')
home_dir := env('HOME')
mount := absolute_path('mount')

# user := env('USER')
# {{justfile-directory()}}
#

prefix := "ferris-"
all_dirs := "user zmk-config zmk-modules zmk-zephyr zmk-zephyr-modules zmk-zephyr-tools build"

alias b := build-firmware

# mod zmk ".just/zmk.just"

# Open fzf picker
[no-cd]
_default:
    @just --choose

# Zmk-Config
#
# podman volume create --driver local -o o=bind -o type=none \
#  -o device="/absolute/path/to/zmk-config/" zmk-config
#
# Modules
#
# podman volume create --driver local -o o=bind -o type=none \
#   -o device="/absolute/path/to/zmk-modules/parent/" zmk-modules

setup-volumes:
    echo {{ justfile_directory() }}

# Set up directories and volumes
generate-dev-md:
    #!/bin/bash
    for i in {{ all_dirs }}; do
      name="{{ prefix }}$i"
      path="{{ justfile_directory() }}/${name}"
      printf "\n\n%s\n" "${path}"
      mkdir -p "${path}"
      podman volume create --driver local -o o=bind -o type=none -o device="${path}" "${name}"
    done

recipe context +collection:
    #!/usr/bin/env bash
    if [ '{{ collection }}' != '' ]; then
      for item in {{ collection }}; do
        echo just dynamic-{{ context }} $item
      done
    else
      echo "No collection to process with dynamic-{{ context }}"
    fi

# podman-env:
#     mkdir -p "{{ mount }}/user"
#     mkdir -p "{{ mount }}/zmk-config"
#     mkdir -p "{{ mount }}/zmk-modules"
#     mkdir -p "{{ mount }}/zmk-zephyr"
#     mkdir -p "{{ mount }}/zmk-zephyr-modules"
#     mkdir -p "{{ mount }}/zmk-zephyr-tools"
#     mkdir -p "{{ mount }}/build"
#
#     podman run \
#       --rm -it \
#       --workdir /workspaces \
#       -v "{{ mount }}/user":/root \
#       -v "{{ justfile_directory() }}/config":/workspaces/config \
#       -v "{{ mount }}/zmk-config":/workspaces/zmk-config \
#       -v "{{ mount }}/zmk-modules":/workspaces/zmk-modules \
#       -v "{{ mount }}/zmk-zephyr":/workspaces/zephyr \
#       -v "{{ mount }}/zmk-zephyr-modules":/workspaces/modules \
#       -v "{{ mount }}/zmk-zephyr-tools":/workspaces/tools \
#       -v "{{ mount }}/build":/workspaces/build \
#       docker.io/zmkfirmware/zmk-dev-arm:3.5
#
# build-lily-firmware:
#     nix build .#firmware
#     rm -rf ./uf2
#     mkdir -p ./uf2
#     cp ./result/zmk_left.uf2 uf2/
#     cp ./result/zmk_right.uf2 uf2/
#     chown -R "$USER" ./uf2/

# \ls ./flake.nix |  entr -d -c just layout-img
layout-img:
    nix build .#layoutImage
    rm -rf ./imgs
    mkdir -p ./imgs
    cp result/* imgs/
    chown -R "$USER" ./imgs/
    # not required! TODO: same for uf2 probably...
    # find ./result/ -type f -exec cp "$(readlink -f {})" ./imgs \;

# alias -g fullauto="find \$PWD -name '.*' -prune -o -print | entr zsh -c \"git commit -am 'auto' && git push\""

local-layout:
    firefox "file://{{ justfile_directory() }}/sweep_keymap.ortho.svg"
    find "`pwd`/config/" -name '.*' -prune -o -print | entr -cd zsh -c 'pipx run keymap-drawer parse --columns 10 -z ./config/cradio.keymap > sweep_keymap.yaml && pipx run keymap-drawer draw sweep_keymap.yaml > sweep_keymap.ortho.svg'

develop-layout:
    # @just layout-img
    firefox "file://{{ justfile_directory() }}/result/layout.svg"
    # fd -epdf . result/ | head -n1 | xargs xdg-open
    # TODO: send command to refresh firefox??
    find "`pwd`/config/" -name '.*' -prune -o -print | entr -cd zsh -c 'nix build .#layoutImage'
    # find "`pwd`/config/" -name '.*' -prune -o -print | entr -cd zsh -c 'nix build .#layoutImage && fd -epdf . result/ | head -n1 | xargs xdg-open'
    # \ls "config/" | entr -d nix build .#layoutImage

# parse & plot keymap
draw:
    #!/usr/bin/env bash
    set -euo pipefail
    keymap -c "{{ draw }}/config.yaml" parse -z "{{ config }}/cradio.keymap" --virtual-layers Combos >"{{ draw }}/base.yaml"
    # yq -Yi '.combos.[].l = ["Combos"]' "{{ draw }}/base.yaml"
    keymap -c "{{ draw }}/config.yaml" draw "{{ draw }}/base.yaml" -k "ferris/sweep" >"{{ draw }}/base.svg"

# # initialize west
# west-init:
#     # git config --global --add safe.directory /workspaces/ferris-sweep-zmk-nix/zmk
#     west init -l config
#     west update --fetch-opt=--filter=blob:none
#     west zephyr-export
#     git config --global --add safe.directory ./zmk
#     git config --global --add safe.directory ./zephyr

# # Builds with ZMK Studio
# build-firmware:
#     #!/usr/bin/env bash
#     set -euxo pipefail
#
#     # -p # --pristine
#     #         -s "zmk/app" # the -s is not required, apparently
#
#     build_dir="{{ build }}/left";
#     mkdir -p "${build_dir}";
#     west build \
#         -p \
#         --build-dir "${build_dir}" \
#         --board "nice_nano_v2" \
#         --snippet "studio-rpc-usb-uart" \
#         "{{ justfile_directory() }}/zmk/app" \
#         -- \
#         -DZMK_CONFIG="{{ config }}" \
#         -DSHIELD="cradio_left" \
#         -DCONFIG_ZMK_STUDIO="y";
#
#     if [[ -f "${build_dir}/zephyr/zmk.uf2" ]]; then
#         mkdir -p "{{ out }}" && cp "${build_dir}/zephyr/zmk.uf2" "{{ out }}/zmk_left.uf2"
#     fi
#
#     build_dir="{{ build }}/right";
#     mkdir -p "${build_dir}";
#     west build \
#         -p \
#         --build-dir "${build_dir}" \
#         --board "nice_nano_v2" \
#         "{{ justfile_directory() }}/zmk/app" \
#         -- \
#         -DZMK_CONFIG="{{ config }}" \
#         -DSHIELD="cradio_right";
#
#     if [[ -f "${build_dir}/zephyr/zmk.uf2" ]]; then
#         mkdir -p "{{ out }}" && cp "${build_dir}/zephyr/zmk.uf2" "{{ out }}/zmk_right.uf2"
#     fi

# update west
update:
    west update --fetch-opt=--filter=blob:none

# # clear build cache and artifacts
# clean:
#     rm -rf {{ build }} {{ out }}
#
# # clear all automatically generated files
# clean-all: clean
#     rm -rf .west zmk zephyr modules
#
# # clear nix cache
# clean-nix:
#     nix-collect-garbage --delete-old

# flash-left: build-firmware
#   printf "plug in left kb..."
#   cp $(readlink -f ./result/zmk_left.uf2) "/media/$USER/NICENANO/"
#   # nix run .#flash --debug
# copy uf2 to non-link
# find ./result/ -type l -exec readlink -f {} \;
# cp $(readlink -f result/zmk_left.uf2) left.uf2
# fd . -tl result -x readlink -f
#
# during the flashing: open /media/imochoa

flash-kb:
    open "/media/$USER"
    # nix run .#flash --debug
    nix run .#flash

# just build-firmware
# printf "start bootloader on LEFT shield"
# open "/media/${USER}"
# out="/media/${USER}/NICENANO/"
# while [ ! -d "${out}" ]; do
#   printf "."
#   sleep 1
# done
# printf "\n%s" "copying uf2"
# cp "$(readlink -f result/zmk_left.uf2)" "${out}"
# TODO look into watchman!
# copy uf2 to non-link
# find ./result/ -type l -exec readlink -f {} \;
# cp $(readlink -f result/zmk_left.uf2) left.uf2
# fd . -tl result -x readlink -f
#
# during the flashing: open /media/imochoa
# macos -> ls /Volumes/NICENANO/

fmt-just:
    @just --fmt --unstable


devc-mkdirs:
    mkdir -p "{{ justfile_directory() }}/modules"
    mkdir -p "{{ justfile_directory() }}/zmk"
    mkdir -p "{{ justfile_directory() }}/zephyr"
    mkdir -p "{{ justfile_directory() }}/.cache"
    mkdir -p "{{ justfile_directory() }}/.build"
    mkdir -p "{{ justfile_directory() }}/.tools"
    # should be made via the init recipe: .west
    # mkdir -p "{{ justfile_directory() }}/.west"
    mkdir -p "{{ justfile_directory() }}/.home"

devc-hard-rmdirs: && devc-mkdirs
    rm -rf "{{ justfile_directory() }}/modules"
    rm -rf "{{ justfile_directory() }}/zmk"
    rm -rf "{{ justfile_directory() }}/zephyr"
    rm -rf "{{ justfile_directory() }}/.cache"
    rm -rf "{{ justfile_directory() }}/.build"
    rm -rf "{{ justfile_directory() }}/.tools"
    rm -rf "{{ justfile_directory() }}/.west"
    rm -rf "{{ justfile_directory() }}/.home"

# initialize west
west-init: devc-hard-rmdirs 
    west init -l config

# you might need to run this multiple times after "init"
west-update:
    west update --fetch-opt=--filter=blob:none
    west zephyr-export
    git config --global --add safe.directory "{{ justfile_directory() }}/zmk"
    git config --global --add safe.directory "{{ justfile_directory() }}/zephyr"

xx-west-init:
    @just devc-exec west-init

xx-west-update:
    @just devc-exec update

devc-full-init: xx-west-init xx-west-update
    echo "done!"

devc-exec recipe: devc-up
    devcontainer exec \
      --workspace-folder "{{ justfile_directory() }}" \
      --docker-path podman \
      -- just {{ recipe }}

# devc-testt:
#   @just devc-exec testt
#
# testt:
#   env

devc-build:
    devcontainer build \
      --workspace-folder "{{ justfile_directory() }}" \
      --docker-path podman \
      --remove-existing-container

devc-up:
    devcontainer up \
      --workspace-folder "{{ justfile_directory() }}" \
      --docker-path podman \
      --remove-existing-container

# Builds with ZMK Studio
build-firmware:
    #!/usr/bin/env bash
    set -euxo pipefail
    # https://www.reddit.com/r/ErgoMechKeyboards/comments/1hkhyht/guide_building_zmk_firmware_locally_with_only_a/

    # that you may need to run west update a few times for everything to be fetched.
    # west init -l config && west update
    out="{{ justfile_directory() }}/firmware"

    mkdir -p "${out}"
    rm -rf "${out}/*.uf2"

    # says to call it from zmk/app...
    export Zephyr_DIR="{{ justfile_directory() }}/zephyr/share/zephyr-package/cmake"
    shield="cradio"

    # If you use a local development environment to build firmware instead of GitHub Actions, pass the -DSHIELD=settings_reset argument when building, omitting all other -DSHIELD arguments.

    for side in "left" "right"; do
      build="{{ justfile_directory() }}/.build/${side}"

      echo "${side}"
      echo "${build}"

      rm -rf "${build}"
      mkdir -p "${build}" 

      CMAKE_PREFIX_PATH="{{ justfile_directory() }}/zephyr:\$CMAKE_PREFIX_PATH" west build \
        --pristine \
        --build-dir "${build}" \
        --board "nice_nano_v2" \
        --snippet "studio-rpc-usb-uart" \
        "{{ justfile_directory() }}/zmk/app" \
        -- \
        -DZMK_CONFIG="{{ justfile_directory() }}/config" \
        -DSHIELD="${shield}_${side}" \
        -DCONFIG_ZMK_STUDIO="y"

      if [[ -f "${build}/zephyr/zmk.uf2" ]]; then
        cp "${build}/zephyr/zmk.uf2" "${out}/zmk_${side}.uf2"
      fi
    done

    # redo init if the paths change..., call it multiple times



    #" west build -d /build/left -p -b "nice_nano_v2" \ -s /zmk-urchin/zmk/app \
    # -- -DSHIELD="urchin_left nice_view_adapter nice_view" \ -DZMK_CONFIG="/zmk-urchin/config" \
    # -DZMK_EXTRA_MODULES="/zmk-urchin/urchin-zmk-module"

    # -DZMK_EXTRA_MODULES="/zmk-urchin/urchin-zmk-module"

    # ZMK studio support
    # I won't go into details here. But you'd need the following extra flags in appropriate places to build a studio-compatible firmware. -S studio-rpc-usb-uart \ -DCONFIG_ZMK_STUDIO=y \


xx-build-firmware:
    @just devc-exec build-firmware


# https://zmk.dev/docs/troubleshooting/connection-issues#reset-split-keyboard-procedure 
build-settings-reset-firmware:
    #!/usr/bin/env bash
    set -euxo pipefail
    # https://www.reddit.com/r/ErgoMechKeyboards/comments/1hkhyht/guide_building_zmk_firmware_locally_with_only_a/

    # that you may need to run west update a few times for everything to be fetched.
    # west init -l config && west update
    out="{{ justfile_directory() }}/firmware"

    mkdir -p "${out}"

    # says to call it from zmk/app...
    export Zephyr_DIR="{{ justfile_directory() }}/zephyr/share/zephyr-package/cmake"

    # If you use a local development environment to build firmware instead of GitHub Actions, pass the -DSHIELD=settings_reset argument when building, omitting all other -DSHIELD arguments.
    build="{{ justfile_directory() }}/.build/settings_reset"

    echo "${build}"

    rm -rf "${build}"
    mkdir -p "${build}" 

    CMAKE_PREFIX_PATH="{{ justfile_directory() }}/zephyr:\$CMAKE_PREFIX_PATH" west build \
      --pristine \
      --build-dir "${build}" \
      --board "nice_nano_v2" \
      "{{ justfile_directory() }}/zmk/app" \
      -- \
      -DZMK_CONFIG="{{ justfile_directory() }}/config" \
      -DSHIELD="settings_reset"

    if [[ -f "${build}/zephyr/zmk.uf2" ]]; then
      cp "${build}/zephyr/zmk.uf2" "${out}/zmk_reset.uf2"
    fi

xx-settings-reset-firmware:
    @just devc-exec build-settings-reset-firmware

# -v "{{ mount }}/user":/root \
