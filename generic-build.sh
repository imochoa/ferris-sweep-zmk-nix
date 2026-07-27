#!/usr/bin/env bash

set -exo pipefail

# https://www.reddit.com/r/ErgoMechKeyboards/comments/1hkhyht/guide_building_zmk_firmware_locally_with_only_a/


# BOARD
# SHIELD
# SNIPPET
# CMAKE_ARGS
artifact_name=""

: Check env variables
for var in "BOARD" "SHIELD" "SNIPPET" "CMAKE_ARGS"; do
    [[ -z "${var}" ]] && echo -e "OK!" || echo -e "\033[0;41mMISSING\033[0m"
done

# says to call it from zmk/app...
out="./firmware"
artifact_name="${artifact_name:-${SHIELD}-${BOARD}-zmk}"

: Check permissions and directories
for dir in "." "${out}"; do
    printf "Checking  %s...\n" "${dir}";
    [[ $(stat -f "%g" "${dir}") -eq 1000 ]] && echo -e "OK!" || echo -e "\033[0;41mOWNER WAS NOT 1000\033[0m"
    [[ -d "${dir}" ]] && echo -e "OK!" || echo -e "\033[0;41mDIRECTORY MISSING\033[0m"
done

# #  " -DZMK_EXTRA_MODULES='/workspace'"

# : CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}
# : Zephyr_DIR=${Zephyr_DIR}
# # "./zephyr/share/zephyr-package/cmake"

# # that you may need to run west update a few times for everything to be fetched.
# # west init -l config && west update
# mkdir -p "${out}"
# build="./.build/${BOARD}/${SHIELD}"
# mkdir -p "${build}"

# export Zephyr_DIR="./zephyr/share/zephyr-package/cmake"

# # If you use a local development environment to build firmware instead of GitHub Actions, pass the -DSHIELD=settings_reset argument when building, omitting all other -DSHIELD arguments.

# rm -rf "${build}"
# mkdir -p "${build}" 

# CMAKE_PREFIX_PATH="./zephyr:${CMAKE_PREFIX_PATH}" west build \
#     --pristine \
#     --build-dir "${build}" \
#     --board "${BOARD}" \
#     --snippet "${SNIPPET}" \
#     "./zmk/app" \
#     -- \
#     -DZMK_CONFIG="./config" \
#     -DSHIELD="${SHIELD}" \
#     ${CMAKE_ARGS}

# # # TODO: technically also .bin files exist?
# # if [[ -f "${build}/zephyr/zmk.uf2" ]]; then
# # # TODO: artifact_name cradio_left-nice_nano-zmk.uf2"
# #     cp "${build}/zephyr/zmk.uf2" "${out}/${artifact_name}.uf2"
# # fi


# #  _ls_out