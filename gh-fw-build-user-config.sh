# MATRIX
# nix-shell nixpkgs#yq -- -oj -I0 'build.yaml'
# yq --indent 0 < build.yaml

# matrix vars
# board: ${{ matrix.board }}
# shield: ${{ matrix.shield }}
# artifact_name: ${{ matrix.artifact-name }}
# snippet: ${{ matrix.snippet }}

# PREPARE VARIABLES

if [ -e zephyr/module.yml ]; then
  export zmk_load_arg=" -DZMK_EXTRA_MODULES='${GITHUB_WORKSPACE}'"
  new_tmp_dir="${TMPDIR:-/tmp}/zmk-config"
  mkdir -p "${new_tmp_dir}"
  echo "base_dir=${new_tmp_dir}" >>$GITHUB_ENV
else
  echo "base_dir=${GITHUB_WORKSPACE}" >>$GITHUB_ENV
fi

if [ -n "${snippet}" ]; then
  extra_west_args="-S \"${snippet}\""
fi

echo "zephyr_version=${ZEPHYR_VERSION}" >>$GITHUB_ENV
echo "extra_west_args=${extra_west_args}" >>$GITHUB_ENV
echo "extra_cmake_args=${shield:+-DSHIELD=\"$shield\"}${zmk_load_arg}" >>$GITHUB_ENV
echo "display_name=${shield:+$shield - }${board}" >>$GITHUB_ENV
echo "artifact_name=${artifact_name:-${shield:+$shield-}${board//\//_}-zmk}" >>$GITHUB_ENV

# WEST INIT AND UPDATE
west init -l "/__w/ferris-sweep-zmk-nix/ferris-sweep-zmk-nix/config"
shell: sh -e {0}
# env:
#   build_dir: /tmp/tmp.clhtAS7bsR
#   base_dir: /__w/ferris-sweep-zmk-nix/ferris-sweep-zmk-nix
#   zephyr_version: 4.1.0
#   extra_west_args:
#   extra_cmake_args: -DSHIELD="cradio_left"
#   display_name: cradio_left - nice_nano_v2
#   artifact_name: cradio_left-nice_nano_v2-zmk
#
west update --fetch-opt=--filter=tree:0

# EXPORT???
west zephyr-export
# env:
#   build_dir: /tmp/tmp.clhtAS7bsR
#   base_dir: /__w/ferris-sweep-zmk-nix/ferris-sweep-zmk-nix
#   zephyr_version: 4.1.0
#   extra_west_args:
#   extra_cmake_args: -DSHIELD="cradio_left"
#   display_name: cradio_left - nice_nano_v2
#   artifact_name: cradio_left-nice_nano_v2-zmk

# BUILD
west build -s zmk/app -d "/tmp/tmp.clhtAS7bsR" \
  -b "nice_nano_v2" -- \
  -DZMK_CONFIG=/__w/ferris-sweep-zmk-nix/ferris-sweep-zmk-nix/config \
  -DSHIELD="cradio_left"

# RENAME
mkdir "/tmp/tmp.clhtAS7bsR/artifacts"
if [ -f "/tmp/tmp.clhtAS7bsR/zephyr/zmk.uf2" ]; then
  cp "/tmp/tmp.clhtAS7bsR/zephyr/zmk.uf2" "/tmp/tmp.clhtAS7bsR/artifacts/cradio_left-nice_nano_v2-zmk.uf2"
elif [ -f "/tmp/tmp.clhtAS7bsR/zephyr/zmk.bin" ]; then
  cp "/tmp/tmp.clhtAS7bsR/zephyr/zmk.bin" "/tmp/tmp.clhtAS7bsR/artifacts/cradio_left-nice_nano_v2-zmk.bin"
fi
