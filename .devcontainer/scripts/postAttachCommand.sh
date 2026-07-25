#!/usr/bin/env bash
set -euxo pipefail

: Make sure directories exist:
mkdir -p "${HOME}"

: Check permissions for mounted directories
for dir in "." "${HOME}"; do
    printf "Checking group ownership for %s...\n" "${dir}";
    [[ $(stat -c "%g" "${dir}") -eq 1000 ]] && echo -e "OK!" || echo -e "\033[0;41mOWNER WAS NOT 1000\033[0m"
done

just in-devc mkdirs

(unset pipefail
  : west init might fail if already initialized, ignore errors
  just in-devc west-init || true
)

: Might be slow... but update with: 
: just in-devc west-update

just --version
west --version

env

# TODO: 1
# https://v0-3-branch.zmk.dev/docs/development/local-toolchain/ide-integration#create-a-compilation-database
# west config build.cmake-args -- -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# TODO: 2
# https://v0-3-branch.zmk.dev/docs/development/local-toolchain/ide-integration#create-a-cc-configuration

: container=${container}
: ZEPHYR_SDK_VERSION=${ZEPHYR_SDK_VERSION}
: ZEPHYR_VERSION=${ZEPHYR_VERSION}
