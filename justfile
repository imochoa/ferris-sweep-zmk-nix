set positional-arguments := true

# -e Exit immediately if a command exits with a non-zero status.
# -u Treat unbound variables as an error when substituting.
# -c If set, commands are read from string. This option is used to provide commands that don't come from a file.
# -o pipefail If any command in a pipeline fails, that return code will be used as the return code of the whole pipeline.

set shell := ["bash", "-euco", "pipefail"]

alias b := build-firmware

# Open fzf picker
[no-cd]
_default:
    @just --choose


flash-kb:
  nix run .#flash --debug

build-firmware:
  nix build .#firmware

# TODO look into watchman!
# \ls ./flake.nix |  entr -d -c just layout-img
layout-img:
  nix build .#layoutImage
