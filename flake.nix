{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      zmk-nix,
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
      lib = nixpkgs.lib;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        rec {
          default = firmware;

          flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };

          update = zmk-nix.packages.${system}.update;

          firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
            # Need to be configured!
            board = "nice_nano_v2";
            shield = "cradio_%PART%";
            enableZmkStudio = true;
            extraCmakeFlags = [ "-DCONFIG_ZMK_STUDIO=y" ];
            # Defaults
            name = "firmware";
            src = nixpkgs.lib.sourceFilesBySuffices self [
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
            zephyrDepsHash = "sha256-FzDnh6e0u+Zy1JYW7exQrP1I8C5EECnnMHQN5dpJP2o=";
            meta = {
              description = "ZMK firmware";
              license = nixpkgs.lib.licenses.mit;
              platforms = nixpkgs.lib.platforms.all;
            };
          };

          layoutImage =
            let
              keymap-drawer = import ./keymap-drawer.nix { inherit pkgs lib; };
            in
            pkgs.runCommand "layout"
              {
                nativeBuildInputs = [
                  keymap-drawer
                  pkgs.inkscape
                ];
              }
              ''
                mkdir -p $out

                # Pointing to the nix store directly would change the name!
                # BUT THE FILENAME IS IMPORTANT!
                ln -s ${./config} config

                # ${keymap-drawer}/bin/keymap
                # Generate keymap.yaml
                DRAWER_CONF="$out/keymap-drawer-config.yaml"
                LAYOUT_SVG="$out/layout.svg"
                keymap parse --columns 10 --zmk-keymap "config/cradio.keymap" > "''${DRAWER_CONF}"

                # Use it to output SVG
                keymap draw "''${DRAWER_CONF}" > "''${LAYOUT_SVG}"

                # inkscape is quite fat... but it works
                inkscape "''${LAYOUT_SVG}" --export-filename="$out/layout.pdf"
                inkscape "''${LAYOUT_SVG}" --export-filename="$out/layout.png"
              '';

        }
      );

      devShells = forAllSystems (system: {
        default = zmk-nix.devShells.${system}.default;
      });

    };
}
