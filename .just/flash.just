set positional-arguments := true

set shell := ["bash", "-euco", "pipefail"]


# draw := absolute_path('draw')
draw := justfile_directory()/'draw'
config := justfile_directory()/'config'

[no-cd]
flash-kb:
    open "/media/$USER"
    # nix run .#flash --debug
    nix run .#flash

# flash-left: build-firmware
#   printf "plug in left kb..."
#   cp $(readlink -f ./result/zmk_left.uf2) "/media/$USER/NICENANO/"
#   # nix run .#flash --debug
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

