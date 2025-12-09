set positional-arguments := true

set shell := ["bash", "-euco", "pipefail"]


# out := justfile_directory()/'config'
out := absolute_path( justfile_directory() + "/firmware")

debugit:
    echo {{absolute_path( justfile_directory() + "/firmware" ) }}
    echo {{ justfile_directory() + "/firmware"}}

[no-cd]
reset-firmware: (_flash "zmk_reset.uf2" "zmk_reset.uf2")

[no-cd]
firmware: (_flash "zmk_left.uf2" "zmk_right.uf2")

[no-cd]
_flash fm_left fm_right:
  #!/usr/bin/env bash
  set -euxo pipefail
  tmpdir=$(mktemp -d)
  pushd "${tmpdir}" > /dev/null
  # timestamp file
  ts="${tmpdir}/ts"
  trap 'popd && rm -rf "${tmpdir}"' EXIT

  # ref: https://github.com/lilyinstarlight/zmk-nix/blob/f02a78c8c06d283ea1399c14aaec308bfb77dc1b/nix/flash.nix#L8
  # TODO: check for darwin
  # kb_dir="/media/$USER"
  kb_dir="/Volumes/"

  for f in "{{fm_left}}" "{{fm_right}}";
  do

    uf2="{{ out }}/${f}"
    [ ! -f "${uf2}" ] && exit 1

    printf "Bootloader ${f}\n"
    rm -rf "${ts}" && touch "${ts}"
    res=""
    while [[ -z ${res} ]]; do
      printf "."
      sleep 1
      res=$(find "${kb_dir}" -type d -maxdepth 1 -depth 1 -newer "${ts}");
      # echo $( printf "%s" "${res}" | wc -l  )
      # printf "%s" "${res}"
    done
    bl_dir=$(head -n 1 <<< "${res}" )
    : sudo is required in macOS to not get a permission error copying to the removable drive...
    sudo cp "${uf2}" "${bl_dir}"
  done



  ts="${tmpdir}/ts"
  touch "${ts}"

  # sleep 10
  printf "bootloader Left\n"
  res=""
  while [ $( printf "%s" "${res}" | wc -l  ) -lt 0 ]; do
    printf "."
    sleep 1
    res=$(find "${kb_dir}" -type d -depth 1 -newer "${ts}");
    # echo $( printf "%s" "${res}" | wc -l  )
    # printf "%s" "${res}"
  done
  bl_dir=$(printf "%s" "${res}" | head -n 1)
  # echo $(find "${kb_dir}" -type d -depth 1 -newer "${ts}")
  # rm "${ts}"
  # echo $bl_dir

# while [ ! -d "${out}" ]; do
#   printf "."
#   sleep 1
# done
# find . -type d -depth 1
# find . -type d -depth 1 -newer ./pooper
# DIRDIFF=$(diff "$WATCHDIR"/.oldfiles $NEWFILESNAME | cut -f 2 -d "")
#   printf "plug in left kb..."
#   cp $(readlink -f ./result/zmk_left.uf2) "/media/$USER/NICENANO/"

# copy uf2 to non-link
# find ./result/ -type l -exec readlink -f {} \;
# cp $(readlink -f result/zmk_left.uf2) left.uf2
# fd . -tl result -x readlink -f
#
# during the flashing: open /media/imochoa

# just build-firmware
# printf "start bootloader on LEFT shield"
# open "/media/${USER}"
# out="/media/${USER}/NICENANO/"
# while [ ! -d "${out}" ]; do
#   printf "."
#   sleep 1
# done
# printf "\n%s" "copying uf2"
# cp "$(readlink -f result/zmk_left.uf2)" "${out}"
# TODO look into watchman!
# copy uf2 to non-link
# find ./result/ -type l -exec readlink -f {} \;
# cp $(readlink -f result/zmk_left.uf2) left.uf2
# fd . -tl result -x readlink -f
#
# during the flashing: open /media/imochoa
# macos -> ls /Volumes/NICENANO/

