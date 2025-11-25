set positional-arguments := true
set shell := ["bash", "-euco", "pipefail"]

config := absolute_path('config')
out := absolute_path('firmware')
build := absolute_path('.build')

# user := env('USER')
# {{justfile-directory()}}
#

prefix := "ferris-"
all_dirs := "user zmk-config zmk-modules zmk-zephyr zmk-zephyr-modules zmk-zephyr-tools build"

# alias b := build-firmware

mod draw ".just/draw.just"
mod in-devc ".just/in-devc.just"

# Open fzf picker
[no-cd]
_default:
    @just --choose

# recipe context +collection:
#     #!/usr/bin/env bash
#     if [ '{{ collection }}' != '' ]; then
#       for item in {{ collection }}; do
#         echo just dynamic-{{ context }} $item
#       done
#     else
#       echo "No collection to process with dynamic-{{ context }}"
#     fi

fmt-just:
    @just --fmt --unstable
    cd .just/ && just --fmt --unstable

# devc-mkdirs:
#     mkdir -p "{{ justfile_directory() }}/modules"
#     mkdir -p "{{ justfile_directory() }}/zmk"
#     mkdir -p "{{ justfile_directory() }}/zephyr"
#     mkdir -p "{{ justfile_directory() }}/.cache"
#     mkdir -p "{{ justfile_directory() }}/.build"
#     mkdir -p "{{ justfile_directory() }}/.tools"
#     mkdir -p "{{ justfile_directory() }}/.home"
#     # .west should be made via the init recipe!
#     # mkdir -p "{{ justfile_directory() }}/.west"
#
# devc-hard-rmdirs: && devc-mkdirs
#     rm -rf "{{ justfile_directory() }}/modules"
#     rm -rf "{{ justfile_directory() }}/zmk"
#     rm -rf "{{ justfile_directory() }}/zephyr"
#     rm -rf "{{ justfile_directory() }}/.cache"
#     rm -rf "{{ justfile_directory() }}/.build"
#     rm -rf "{{ justfile_directory() }}/.tools"
#     rm -rf "{{ justfile_directory() }}/.west"
#     rm -rf "{{ justfile_directory() }}/.home"
# # initialize west
# west-init: devc-hard-rmdirs
#     west init -l config
#
# # you might need to run this multiple times after "init"
# west-update:
#     west update --fetch-opt=--filter=blob:none
#     west zephyr-export
#     git config --global --add safe.directory "{{ justfile_directory() }}/zmk"
#     git config --global --add safe.directory "{{ justfile_directory() }}/zephyr"
# # update west
# update:
#     west update --fetch-opt=--filter=blob:none
# xx-west-init:
#     @just devc-exec west-init
#
# xx-west-update:
#     @just devc-exec update
# devc-full-init: xx-west-init xx-west-update
#     echo "done!"

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
      --remove-existing-container

# # Builds with ZMK Studio
# build-firmware:
#     #!/usr/bin/env bash
#     set -euxo pipefail
#     # https://www.reddit.com/r/ErgoMechKeyboards/comments/1hkhyht/guide_building_zmk_firmware_locally_with_only_a/
#
#     # that you may need to run west update a few times for everything to be fetched.
#     # west init -l config && west update
#     out="{{ justfile_directory() }}/firmware"
#
#     mkdir -p "${out}"
#     rm -rf "${out}/*.uf2"
#
#     # says to call it from zmk/app...
#     export Zephyr_DIR="{{ justfile_directory() }}/zephyr/share/zephyr-package/cmake"
#     shield="cradio"
#
#     # If you use a local development environment to build firmware instead of GitHub Actions, pass the -DSHIELD=settings_reset argument when building, omitting all other -DSHIELD arguments.
#
#     for side in "left" "right"; do
#       build="{{ justfile_directory() }}/.build/${side}"
#
#       echo "${side}"
#       echo "${build}"
#
#       rm -rf "${build}"
#       mkdir -p "${build}"
#
#       CMAKE_PREFIX_PATH="{{ justfile_directory() }}/zephyr:\$CMAKE_PREFIX_PATH" west build \
#         --pristine \
#         --build-dir "${build}" \
#         --board "nice_nano_v2" \
#         --snippet "studio-rpc-usb-uart" \
#         "{{ justfile_directory() }}/zmk/app" \
#         -- \
#         -DZMK_CONFIG="{{ justfile_directory() }}/config" \
#         -DSHIELD="${shield}_${side}" \
#         -DCONFIG_ZMK_STUDIO="y"
#
#       if [[ -f "${build}/zephyr/zmk.uf2" ]]; then
#         cp "${build}/zephyr/zmk.uf2" "${out}/zmk_${side}.uf2"
#       fi
#     done
#
#     # redo init if the paths change..., call it multiple times
#
#
#
#     #" west build -d /build/left -p -b "nice_nano_v2" \ -s /zmk-urchin/zmk/app \
#     # -- -DSHIELD="urchin_left nice_view_adapter nice_view" \ -DZMK_CONFIG="/zmk-urchin/config" \
#     # -DZMK_EXTRA_MODULES="/zmk-urchin/urchin-zmk-module"
#
#     # -DZMK_EXTRA_MODULES="/zmk-urchin/urchin-zmk-module"
#
#     # ZMK studio support
#     # I won't go into details here. But you'd need the following extra flags in appropriate places to build a studio-compatible firmware. -S studio-rpc-usb-uart \ -DCONFIG_ZMK_STUDIO=y \
#
# _a recipe:
#   echo "{{ recipe }}"
#   @mkdir "{{ recipe }}"
#   @touch "{{ recipe }}/default.conf"
#
# test: (_a 'test')
#
# live: (_a 'live')
# always-in-devc:
#     #!/usr/bin/env bash
#     # set -euxo pipefail
#     if [ -z "$IS_DEVCONTAINER" ]; then # Re-invoke self INSIDE devcontainer (single call site)
#       printf "NOT in devc\n"
#       exec just devc-exec "always-in-devc"
#     fi
#
#     printf "IN devc"
# python recipes/my_recipe.py "$@"
# xx-build-firmware:
#     @just devc-exec build-firmware
# # https://zmk.dev/docs/troubleshooting/connection-issues#reset-split-keyboard-procedure
# build-settings-reset-firmware:
#     #!/usr/bin/env bash
#     set -euxo pipefail
#     # https://www.reddit.com/r/ErgoMechKeyboards/comments/1hkhyht/guide_building_zmk_firmware_locally_with_only_a/
#
#     # that you may need to run west update a few times for everything to be fetched.
#     # west init -l config && west update
#     out="{{ justfile_directory() }}/firmware"
#
#     mkdir -p "${out}"
#
#     # says to call it from zmk/app...
#     export Zephyr_DIR="{{ justfile_directory() }}/zephyr/share/zephyr-package/cmake"
#
#     # If you use a local development environment to build firmware instead of GitHub Actions, pass the -DSHIELD=settings_reset argument when building, omitting all other -DSHIELD arguments.
#     build="{{ justfile_directory() }}/.build/settings_reset"
#
#     echo "${build}"
#
#     rm -rf "${build}"
#     mkdir -p "${build}"
#
#     CMAKE_PREFIX_PATH="{{ justfile_directory() }}/zephyr:\$CMAKE_PREFIX_PATH" west build \
#       --pristine \
#       --build-dir "${build}" \
#       --board "nice_nano_v2" \
#       "{{ justfile_directory() }}/zmk/app" \
#       -- \
#       -DZMK_CONFIG="{{ justfile_directory() }}/config" \
#       -DSHIELD="settings_reset"
#
#     if [[ -f "${build}/zephyr/zmk.uf2" ]]; then
#       cp "${build}/zephyr/zmk.uf2" "${out}/zmk_reset.uf2"
#     fi
# xx-settings-reset-firmware:
#     @just devc-exec build-settings-reset-firmware

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
