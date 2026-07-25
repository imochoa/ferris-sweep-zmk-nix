set positional-arguments := true
set shell := ["bash", "-euco", "pipefail"]

out := absolute_path( justfile_dir() + "/firmware")

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
    mkdir -p "{{ justfile_dir() }}/modules"
    mkdir -p "{{ justfile_dir() }}/zmk"
    mkdir -p "{{ justfile_dir() }}/.build"
    mkdir -p "{{ justfile_dir() }}/tools"
    # mkdir -p "{{ justfile_dir() }}/bootloader"
    # mkdir -p "{{ justfile_dir() }}/.home"

    # .west should be made via the init recipe!
    # mkdir -p "{{ justfile_dir() }}/.west"

    # Should be volumes!
    # mkdir -p "{{ justfile_dir() }}/zephyr"

[no-cd]
hard-rmdirs: _devc-check && mkdirs
    rm -rf "{{ justfile_dir() }}/modules"
    rm -rf "{{ justfile_dir() }}/zmk"
    rm -rf "{{ justfile_dir() }}/.build"
    rm -rf "{{ justfile_dir() }}/tools"
    # rm -rf "{{ justfile_dir() }}/bootloader"
    rm -rf "{{ justfile_dir() }}/.west"
    rm -rf "{{ justfile_dir() }}/.home"

    # Should be volumes!
    rm -rf "{{ justfile_dir() }}/zephyr/"*

# initialize west
[group('west')]
[no-cd]
west-init:
    ( unset ZEPHYR_BASE && west init --local "{{ justfile_dir() }}/config" )

[group('west')]
[no-cd]
west-reset: hard-rmdirs west-init

# you might need to run this multiple times after "init"
[group('west')]
[no-cd]
west-update:
    # unset ZEPHYR_BASE??
    # The named volumes are owned by uid 999 (a podman-on-mac artifact),
    # so git running as root flags them as "dubious ownership". Exempt them
    # *before* west update tries to touch the repos.
    git config --global --add safe.directory "{{ justfile_dir() }}/zmk"
    git config --global --add safe.directory "{{ justfile_dir() }}/zephyr"
    git config --global --add safe.directory "*"
    west update --fetch-opt=--filter=blob:none
    west zephyr-export

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
    build="{{ justfile_dir() }}/.build/${board}/${shield}"
    mkdir -p "${build}"

    export Zephyr_DIR="{{ justfile_dir() }}/zephyr/share/zephyr-package/cmake"

    # If you use a local development environment to build firmware instead of GitHub Actions, pass the -DSHIELD=settings_reset argument when building, omitting all other -DSHIELD arguments.

    rm -rf "${build}"
    mkdir -p "${build}" 

    # Only pass --snippet when a snippet is actually requested; an empty
    # --snippet makes west/cmake misparse the following positional args.
    snippet_flag=()
    if [[ -n "${snippet}" ]]; then
      snippet_flag=(--snippet "${snippet}")
    fi

    CMAKE_PREFIX_PATH="{{ justfile_dir() }}/zephyr:\$CMAKE_PREFIX_PATH" west build \
      --pristine \
      --build-dir "${build}" \
      --board "${board}" \
      "${snippet_flag[@]}" \
      "{{ justfile_dir() }}/zmk/app" \
      -- \
      -DZMK_CONFIG="{{ justfile_dir() }}/config" \
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

