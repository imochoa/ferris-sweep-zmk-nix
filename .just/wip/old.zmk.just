set positional-arguments := true

set shell := ["bash", "-euco", "pipefail"]

config := absolute_path('../config')
out := absolute_path('../firmware')
build := absolute_path('../.build')
# result := absolute_path('../result')
# draw := absolute_path('../draw')
# home_dir := env('HOME')
mount := absolute_path('../mount')

shield := "ergogenesis"

[no-cd]
n-podman-env:
  mkdir -p "{{mount}}/user"
  mkdir -p "{{mount}}/zmk-config"
  mkdir -p "{{mount}}/zmk-modules"
  mkdir -p "{{mount}}/zmk-zephyr"
  mkdir -p "{{mount}}/zmk-zephyr-modules"
  mkdir -p "{{mount}}/zmk-zephyr-tools"
  mkdir -p "{{mount}}/build"

  podman run \
    --rm -it \
    --workdir /workspaces \
    -v "{{mount}}/user":/root \
    -v "{{justfile_directory()}}/config":/workspaces/config \
    -v "{{mount}}/zmk-config":/workspaces/zmk-config \
    -v "{{mount}}/zmk-modules":/workspaces/zmk-modules \
    -v "{{mount}}/zmk-zephyr":/workspaces/zephyr \
    -v "{{mount}}/zmk-zephyr-modules":/workspaces/modules \
    -v "{{mount}}/zmk-zephyr-tools":/workspaces/tools \
    -v "{{mount}}/build":/workspaces/build \
    docker.io/zmkfirmware/zmk-dev-arm:3.5

# initialize west
[no-cd]
west-init:
    # git config --global --add safe.directory /workspaces/ferris-sweep-zmk-nix/zmk
    west init -l config
    west update --fetch-opt=--filter=blob:none
    west zephyr-export
    git config --global --add safe.directory ./zmk
    git config --global --add safe.directory ./zephyr


# Builds with ZMK Studio
[no-cd]
build-firmware: && _ls_out
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
        -DSHIELD="{{ shield }}_left" \
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
        -DSHIELD="{{ shield }}_right";

    if [[ -f "${build_dir}/zephyr/zmk.uf2" ]]; then
        mkdir -p "{{ out }}" && cp "${build_dir}/zephyr/zmk.uf2" "{{ out }}/zmk_right.uf2"
    fi

# update west
[no-cd]
update:
    west update --fetch-opt=--filter=blob:none

# clear build cache and artifacts
[no-cd]
clean:
    rm -rf "{{ build }}" "{{ out }}"

# clear all automatically generated files
[no-cd]
clean-all: clean
    rm -rf .west zmk zephyr modules

_ls_out:
    ls -la "{{out}}"
