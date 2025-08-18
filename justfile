set positional-arguments := true



# config := absolute_path('config')
# build := absolute_path('.build')
# out := absolute_path('firmware')
# draw := absolute_path('draw')

# -e Exit immediately if a command exits with a non-zero status.
# -u Treat unbound variables as an error when substituting.
# -c If set, commands are read from string. This option is used to provide commands that don't come from a file.
# -o pipefail If any command in a pipeline fails, that return code will be used as the return code of the whole pipeline.

set shell := ["bash", "-euco", "pipefail"]

alias b := build-firmware

# Open fzf picker
[no-cd]
_default:
    @just --choose

flash-left: build-firmware
  printf "plug in left kb..."
  cp $(readlink -f ./result/zmk_left.uf2) "/media/$USER/NICENANO/"
  # nix run .#flash --debug
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

build-firmware:
  nix build .#firmware
  rm -rf ./uf2
  mkdir -p ./uf2
  cp ./result/zmk_left.uf2 uf2/
  cp ./result/zmk_right.uf2 uf2/
  chown -R "$USER" ./uf2/


# TODO look into watchman!
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

# copy uf2 to non-link
# find ./result/ -type l -exec readlink -f {} \;
# cp $(readlink -f result/zmk_left.uf2) left.uf2
# fd . -tl result -x readlink -f
#
# during the flashing: open /media/imochoa

develop-layout:
  # @just layout-img
  firefox "file://{{ justfile_directory() }}/result/layout.svg"
  # fd -epdf . result/ | head -n1 | xargs xdg-open
  # TODO: send command to refresh firefox??
  find "`pwd`/config/" -name '.*' -prune -o -print | entr -cd zsh -c 'nix build .#layoutImage'
  # find "`pwd`/config/" -name '.*' -prune -o -print | entr -cd zsh -c 'nix build .#layoutImage && fd -epdf . result/ | head -n1 | xargs xdg-open'
  # \ls "config/" | entr -d nix build .#layoutImage


# initialize west
init:
    west init -l config
    west update --fetch-opt=--filter=blob:none
    west zephyr-export

# build-single board shield snippet artifact *west_args:
#     #!/usr/bin/env bash
#     set -euo pipefail
#     artifact="${artifact:-${shield:+${shield// /+}-}${board}}"
#     build_dir="{{ build / '$artifact' }}"

#     echo "Building firmware for $artifact..."
#     west build -s zmk/app -d "$build_dir" -b $board {{ west_args }} ${snippet:+-S "$snippet"} -- \
#         -DZMK_CONFIG="{{ config }}" ${shield:+-DSHIELD="$shield"}

#     if [[ -f "$build_dir/zephyr/zmk.uf2" ]]; then
#         mkdir -p "{{ out }}" && cp "$build_dir/zephyr/zmk.uf2" "{{ out }}/$artifact.uf2"
#     else
#         mkdir -p "{{ out }}" && cp "$build_dir/zephyr/zmk.bin" "{{ out }}/$artifact.bin"
#     fi

build-left:
    #!/usr/bin/env bash
    set -euo pipefail

    # snippet and config from zmk
    # [ZMK Studio](https://zmk.dev/docs/features/studio#accessing-zmk-studio)
    
    mkdir -p build/left
    west build -p -s zmk/app -d build/left -b nice_nano_v2 -S "studio-rpc-usb-uart" -- -DZMK_CONFIG="/Users/imochoa/Code/ferris-sweep-zmk-nix/config" -DSHIELD=cradio_left -DCONFIG_ZMK_STUDIO=y
    cp build/left/zephyr/zmk.uf2 ./build/zmk_left.uf2
    
    mkdir -p build/right
    west build -p -s zmk/app -d build/right -b nice_nano_v2 -- -DZMK_CONFIG="/Users/imochoa/Code/ferris-sweep-zmk-nix/config" -DSHIELD=cradio_right
    cp build/right/zephyr/zmk.uf2 ./build/zmk_right.uf2

# -DZMK_EXTRA_MODULES="/Users/imochoa/Code/ferris-sweep-zmk-nix" 
# -DBOARD_ROOT="/Users/imochoa/Code/ferris-sweep-zmk-nix"
# west build -s zmk/app -d build -b nice_nano_v2 -- -DZMK_CONFIG=`realpath config/` -DSHIELD=cradio/
# update west
update:
    west update --fetch-opt=--filter=blob:none


# clear build cache and artifacts
# clean:
#     rm -rf {{ build }} {{ out }}

# clear all automatically generated files
# clean-all: clean
#     rm -rf .west zmk

# clear nix cache
clean-nix:
    nix-collect-garbage --delete-old


