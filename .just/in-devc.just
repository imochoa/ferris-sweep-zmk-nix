set positional-arguments := true
set shell := ["bash", "-euco", "pipefail"]

out := absolute_path( justfile_directory() + "/firmware")

[private]
[no-cd]
_devc-check:
    #!/usr/bin/env bash
    if [ -z "${container}" ]; then
      printf "NOT in devc\n"
      exit 1
    fi

[group('rust recipes')]
[no-cd]
reset-devcontainer:
  podman volume rm zmk-repo-home --force

[no-cd]
mkdirs: _devc-check
    mkdir -p "{{ justfile_directory() }}/modules"
    mkdir -p "{{ justfile_directory() }}/zmk"
    mkdir -p "{{ justfile_directory() }}/zephyr"
    mkdir -p "{{ justfile_directory() }}/.build"
    mkdir -p "{{ justfile_directory() }}/tools"
    # mkdir -p "{{ justfile_directory() }}/bootloader"
    mkdir -p "{{ justfile_directory() }}/.home"

    # .west should be made via the init recipe!
    # mkdir -p "{{ justfile_directory() }}/.west"

[no-cd]
hard-rmdirs: _devc-check && mkdirs
    rm -rf "{{ justfile_directory() }}/modules"
    rm -rf "{{ justfile_directory() }}/zmk"
    rm -rf "{{ justfile_directory() }}/zephyr"
    rm -rf "{{ justfile_directory() }}/.build"
    rm -rf "{{ justfile_directory() }}/tools"
    # rm -rf "{{ justfile_directory() }}/bootloader"
    rm -rf "{{ justfile_directory() }}/.west"
    rm -rf "{{ justfile_directory() }}/.home"

# initialize west
[no-cd]
west-init:
    west init -l config

[no-cd]
west-reset: hard-rmdirs west-init

# you might need to run this multiple times after "init"
[no-cd]
west-update:
    west update --fetch-opt=--filter=blob:none
    west zephyr-export
    git config --global --add safe.directory "{{ justfile_directory() }}/zmk"
    git config --global --add safe.directory "{{ justfile_directory() }}/zephyr"

# Builds with ZMK Studio
# TODO: order matters, so you cannot set cmake_args unless snippet is not empty...
[no-cd]
generic-build board shield snippet="" cmake_args="" artifact_name="": _devc-check && _ls_out
    #!/usr/bin/env bash
    set -euxo pipefail
    # https://www.reddit.com/r/ErgoMechKeyboards/comments/1hkhyht/guide_building_zmk_firmware_locally_with_only_a/

    # says to call it from zmk/app...
    out="{{ out }}"
    board="{{board}}"
    shield="{{shield}}"
    snippet="{{snippet}}"
    cmake_args="{{cmake_args}}"
    artifact_name="{{ artifact_name }}"
    artifact_name="${artifact_name:-${shield}-${board}-zmk}"

    # that you may need to run west update a few times for everything to be fetched.
    # west init -l config && west update
    mkdir -p "${out}"
    build="{{ justfile_directory() }}/.build/${board}/${shield}"
    mkdir -p "${build}"

    export Zephyr_DIR="{{ justfile_directory() }}/zephyr/share/zephyr-package/cmake"

    # If you use a local development environment to build firmware instead of GitHub Actions, pass the -DSHIELD=settings_reset argument when building, omitting all other -DSHIELD arguments.

    rm -rf "${build}"
    mkdir -p "${build}" 

    CMAKE_PREFIX_PATH="{{ justfile_directory() }}/zephyr:\$CMAKE_PREFIX_PATH" west build \
      --pristine \
      --build-dir "${build}" \
      --board "${board}" \
      --snippet "${snippet}" \
      "{{ justfile_directory() }}/zmk/app" \
      -- \
      -DZMK_CONFIG="{{ justfile_directory() }}/config" \
      -DSHIELD="${shield}" \
      ${cmake_args}

    # TODO: technically also .bin files exist?
    if [[ -f "${build}/zephyr/zmk.uf2" ]]; then
    # TODO: artifact_name cradio_left-nice_nano_v2-zmk.uf2"
      cp "${build}/zephyr/zmk.uf2" "${out}/${artifact_name}.uf2"
    fi

[no-cd]
_ls_out:
    ls -la "{{ out }}"

