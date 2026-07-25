#!/usr/bin/env bash

set -e

# Configuration (matching GitHub workflow defaults)
BUILD_MATRIX_PATH="${BUILD_MATRIX_PATH:-build.yaml}"
CONFIG_PATH="${CONFIG_PATH:-config}"
FALLBACK_BINARY="${FALLBACK_BINARY:-bin}"
ARCHIVE_NAME="${ARCHIVE_NAME:-firmware}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo_step() {
    echo -e "${BLUE}==>${NC} ${GREEN}$1${NC}"
}

echo_info() {
    echo -e "${YELLOW}Info:${NC} $1"
}

echo_error() {
    echo -e "${RED}Error:${NC} $1"
}

# Check dependencies
if ! command -v yq &> /dev/null; then
    echo_error "yq is required but not installed. Please install it:"
    echo "  - macOS: brew install yq"
    echo "  - Linux: snap install yq or download from https://github.com/mikefarah/yq"
    exit 1
fi

if ! command -v docker &> /dev/null && ! command -v podman &> /dev/null; then
    echo_error "docker or podman is required but not installed."
    exit 1
fi

# Use docker or podman
if command -v docker &> /dev/null; then
    CONTAINER_CMD="docker"
else
    CONTAINER_CMD="podman"
fi

# Parse build matrix
echo_step "Fetching build matrix from ${BUILD_MATRIX_PATH}"
if [ ! -f "${BUILD_MATRIX_PATH}" ]; then
    echo_error "Build matrix file not found: ${BUILD_MATRIX_PATH}"
    exit 1
fi

# Create output directory
OUTPUT_DIR="$(pwd)/build-output"
mkdir -p "${OUTPUT_DIR}"
echo_info "Output directory: ${OUTPUT_DIR}"

# Get the build matrix as JSON
BUILD_MATRIX_JSON=$(yq -oj -I0 "${BUILD_MATRIX_PATH}")
echo_info "Build matrix:"
yq -oj "${BUILD_MATRIX_PATH}"

# Extract the include array (handles both top-level board/shield and include entries)
INCLUDE_ARRAY=$(echo "${BUILD_MATRIX_JSON}" | yq -oj '.include // []')

# Count number of builds
BUILD_COUNT=$(echo "${INCLUDE_ARRAY}" | yq 'length')

if [ "${BUILD_COUNT}" -eq 0 ]; then
    echo_error "No builds found in ${BUILD_MATRIX_PATH}"
    exit 1
fi

echo_info "Found ${BUILD_COUNT} build(s) to process"
echo ""

# Process each build in the matrix
for i in $(seq 0 $((BUILD_COUNT - 1))); do
    echo_step "Processing build $((i + 1))/${BUILD_COUNT}"

    # Extract matrix variables
    BOARD=$(echo "${INCLUDE_ARRAY}" | yq ".[$i].board // \"\"")
    SHIELD=$(echo "${INCLUDE_ARRAY}" | yq ".[$i].shield // \"\"")
    ARTIFACT_NAME=$(echo "${INCLUDE_ARRAY}" | yq ".[$i].artifact-name // \"\"")
    SNIPPET=$(echo "${INCLUDE_ARRAY}" | yq ".[$i].snippet // \"\"")
    CMAKE_ARGS=$(echo "${INCLUDE_ARRAY}" | yq ".[$i].cmake-args // \"\"")

    if [ -z "${BOARD}" ]; then
        echo_error "Board not specified for build $((i + 1))"
        continue
    fi

    echo_info "Board: ${BOARD}"
    [ -n "${SHIELD}" ] && echo_info "Shield: ${SHIELD}"
    [ -n "${SNIPPET}" ] && echo_info "Snippet: ${SNIPPET}"
    [ -n "${CMAKE_ARGS}" ] && echo_info "CMake args: ${CMAKE_ARGS}"

    # Prepare variables (matching workflow logic)
    EXTRA_CMAKE_ARGS=""
    EXTRA_WEST_ARGS=""
    DISPLAY_NAME="${SHIELD:+$SHIELD - }${BOARD}"
    ARTIFACT_NAME_FINAL="${ARTIFACT_NAME:-${SHIELD:+$SHIELD-}${BOARD//\//_}-zmk}"

    if [ -n "${SHIELD}" ]; then
        EXTRA_CMAKE_ARGS="${EXTRA_CMAKE_ARGS} -DSHIELD=\"${SHIELD}\""
    fi

    if [ -n "${SNIPPET}" ]; then
        EXTRA_WEST_ARGS="-S \"${SNIPPET}\""
    fi

    # Check if this is a module-based config
    BASE_DIR="/tmp/zmk-build"
    if [ -e "zephyr/module.yml" ]; then
        echo_info "Detected zephyr module, using isolated directory"
        EXTRA_CMAKE_ARGS="${EXTRA_CMAKE_ARGS} -DZMK_EXTRA_MODULES='/workspace'"
        BASE_DIR="/tmp/zmk-config"
    fi

    # Create temporary build directory
    BUILD_DIR=$(mktemp -d)
    echo_info "Build directory: ${BUILD_DIR}"

    # Prepare volume mounts and container environment
    WORKSPACE_DIR="$(pwd)"

    echo_step "Running build in container (${DISPLAY_NAME})"

    # Run the build in the ZMK container
    ${CONTAINER_CMD} run --rm \
        -v "${WORKSPACE_DIR}:/workspace" \
        -v "${BUILD_DIR}:/build" \
        -w "${BASE_DIR}" \
        -e "ZEPHYR_VERSION=3.5" \
        zmkfirmware/zmk-build-arm:stable \
        /bin/bash -c "
            set -ex

            # Copy config if using isolated directory
            if [ '${BASE_DIR}' != '/workspace' ]; then
                mkdir -p '${BASE_DIR}/${CONFIG_PATH}'
                cp -R /workspace/${CONFIG_PATH}/* '${BASE_DIR}/${CONFIG_PATH}/'
            else
                BASE_DIR='/workspace'
            fi

            # West init
            west init -l \"\${BASE_DIR}/${CONFIG_PATH}\"

            # West update
            west update --fetch-opt=--filter=tree:0

            # West zephyr export
            west zephyr-export

            # West build
            west build -s zmk/app -d /build -b '${BOARD}' ${EXTRA_WEST_ARGS} -- \
                -DZMK_CONFIG=\"\${BASE_DIR}/${CONFIG_PATH}\" \
                ${EXTRA_CMAKE_ARGS} \
                ${CMAKE_ARGS}

            # Show Kconfig
            echo '=== Kconfig ==='
            if [ -f /build/zephyr/.config ]; then
                grep -v -e '^#' -e '^\$' /build/zephyr/.config | sort || true
            fi

            # Show Devicetree
            echo '=== Devicetree ==='
            if [ -f /build/zephyr/zephyr.dts ]; then
                cat /build/zephyr/zephyr.dts
            elif [ -f /build/zephyr/zephyr.dts.pre ]; then
                cat -s /build/zephyr/zephyr.dts.pre
            fi
        "

    # Copy artifacts
    echo_step "Copying artifacts"
    if [ -f "${BUILD_DIR}/zephyr/zmk.uf2" ]; then
        cp "${BUILD_DIR}/zephyr/zmk.uf2" "${OUTPUT_DIR}/${ARTIFACT_NAME_FINAL}.uf2"
        echo_info "Created: ${OUTPUT_DIR}/${ARTIFACT_NAME_FINAL}.uf2"
    elif [ -f "${BUILD_DIR}/zephyr/zmk.${FALLBACK_BINARY}" ]; then
        cp "${BUILD_DIR}/zephyr/zmk.${FALLBACK_BINARY}" "${OUTPUT_DIR}/${ARTIFACT_NAME_FINAL}.${FALLBACK_BINARY}"
        echo_info "Created: ${OUTPUT_DIR}/${ARTIFACT_NAME_FINAL}.${FALLBACK_BINARY}"
    else
        echo_error "No firmware file found for ${DISPLAY_NAME}"
    fi

    # Cleanup build directory
    rm -rf "${BUILD_DIR}"
    echo ""
done

echo_step "Build complete!"
echo_info "All artifacts are in: ${OUTPUT_DIR}"
ls -lh "${OUTPUT_DIR}"
