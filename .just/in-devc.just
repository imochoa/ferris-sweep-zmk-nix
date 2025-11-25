set positional-arguments := true
set shell := ["bash", "-euco", "pipefail"]

devc-mkdirs:
    mkdir -p "{{ justfile_directory() }}/modules"
    mkdir -p "{{ justfile_directory() }}/zmk"
    mkdir -p "{{ justfile_directory() }}/zephyr"
    mkdir -p "{{ justfile_directory() }}/.build"
    mkdir -p "{{ justfile_directory() }}/.tools"
    mkdir -p "{{ justfile_directory() }}/.home"
    # .west should be made via the init recipe!
    # mkdir -p "{{ justfile_directory() }}/.west"
    #
    # TODO: copy .home to ~/home, then mount
    # in ~
    # .cache
    # .cmake

devc-hard-rmdirs: && devc-mkdirs
    rm -rf "{{ justfile_directory() }}/modules"
    rm -rf "{{ justfile_directory() }}/zmk"
    rm -rf "{{ justfile_directory() }}/zephyr"
    rm -rf "{{ justfile_directory() }}/.build"
    rm -rf "{{ justfile_directory() }}/.tools"
    rm -rf "{{ justfile_directory() }}/.west"
    rm -rf "{{ justfile_directory() }}/.home"

# initialize west
[no-cd]
west-init: devc-hard-rmdirs
    west init -l config

# you might need to run this multiple times after "init"
west-update:
    west update --fetch-opt=--filter=blob:none
    west zephyr-export
    git config --global --add safe.directory "{{ justfile_directory() }}/zmk"
    git config --global --add safe.directory "{{ justfile_directory() }}/zephyr"

# update west
update:
    west update --fetch-opt=--filter=blob:none

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
