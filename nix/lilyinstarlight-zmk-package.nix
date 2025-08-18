{
  lib,
  zmk-nix,
  system,
  self,
}:
zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
  name = "firmware";

  src = lib.sourceFilesBySuffices self [
    ".board"
    ".cmake"
    ".conf"
    ".defconfig"
    ".dts"
    ".dtsi"
    ".json"
    ".keymap"
    ".overlay"
    ".shield"
    ".yml"
    "_defconfig"
    # My additions
    ".h"
  ];

  board = "nice_nano_v2";
  shield = "cradio_%PART%";

  zephyrDepsHash = "sha256-HGdzSpppZuZ2KzBAzGrNImNLf1aUPqlJtEID6yO06Wk=";

  enableZmkStudio = true;
  # extraCmakeFlags = [ "-DCONFIG_ZMK_STUDIO=y" ];
  # https://zmk.dev/docs/development/local-toolchain/build-flash#building-with-external-modules
  extraWestBuildFlags = [
    # "-DZMK_EXTRA_MODULES=''"/urob/zmk-helpers''""
  ];
  # snippets
}

# flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
# update = zmk-nix.packages.${system}.update;
