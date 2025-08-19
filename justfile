set positional-arguments := true
set shell := ["bash", "-euco", "pipefail"]

config := absolute_path('config')
out := absolute_path('firmware')
build := absolute_path('.build')
result := absolute_path('result')
draw := absolute_path('draw')
home_dir := env('HOME')
user := env('USER')

# {{justfile-directory()}}

alias b := build-firmware

# Open fzf picker
[no-cd]
_default:
    @just --choose

build-lily-firmware:
    nix build .#firmware
    rm -rf ./uf2
    mkdir -p ./uf2
    cp ./result/zmk_left.uf2 uf2/
    cp ./result/zmk_right.uf2 uf2/
    chown -R "$USER" ./uf2/

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

# # parse & plot keymap
# draw:
#     #!/usr/bin/env bash
#     set -euo pipefail
#     keymap -c "{{ draw }}/config.yaml" parse -z "{{ config }}/base.keymap" --virtual-layers Combos >"{{ draw }}/base.yaml"
#     yq -Yi '.combos.[].l = ["Combos"]' "{{ draw }}/base.yaml"
#     keymap -c "{{ draw }}/config.yaml" draw "{{ draw }}/base.yaml" -k "ferris/sweep" >"{{ draw }}/base.svg"

# initialize west
west-init:
    west init -l config
    west update --fetch-opt=--filter=blob:none
    west zephyr-export

# Builds with ZMK Studio
build-firmware:
    #!/usr/bin/env bash
    set -euxo pipefail

    # -p # --pristine
    #         -s "zmk/app" # the -s is not required, apparently

    build_dir="{{ build }}/left";
    mkdir -p "${build_dir}";
    west build \
        -p \
        --build-dir "${build_dir}" \
        --board "nice_nano_v2" \
        --snippet "studio-rpc-usb-uart" \
        "{{ justfile_directory() }}/zmk/app" \
        -- \
        -DZMK_CONFIG="{{ config }}" \
        -DSHIELD="cradio_left" \
        -DCONFIG_ZMK_STUDIO="y";

    if [[ -f "${build_dir}/zephyr/zmk.uf2" ]]; then
        mkdir -p "{{ out }}" && cp "${build_dir}/zephyr/zmk.uf2" "{{ out }}/zmk_left.uf2"
    fi

    build_dir="{{ build }}/right";
    mkdir -p "${build_dir}";
    west build \
        -p \
        --build-dir "${build_dir}" \
        --board "nice_nano_v2" \
        "{{ justfile_directory() }}/zmk/app" \
        -- \
        -DZMK_CONFIG="{{ config }}" \
        -DSHIELD="cradio_right";

    if [[ -f "${build_dir}/zephyr/zmk.uf2" ]]; then
        mkdir -p "{{ out }}" && cp "${build_dir}/zephyr/zmk.uf2" "{{ out }}/zmk_right.uf2"
    fi

# update west
update:
    west update --fetch-opt=--filter=blob:none

# clear build cache and artifacts
clean:
    rm -rf {{ build }} {{ out }}

# clear all automatically generated files
clean-all: clean
    rm -rf .west zmk

# clear nix cache
clean-nix:
    nix-collect-garbage --delete-old


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
