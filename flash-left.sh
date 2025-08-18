just build-firmware

printf "start bootloader on LEFT shield"

open "/media/${USER}"

out="/media/${USER}/NICENANO/"

while [ ! -d "${out}" ]; do
  printf "."
  sleep 1
done

printf "\n%s" "copying uf2"
cp "$(readlink -f result/zmk_left.uf2)" "${out}"
