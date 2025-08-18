{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # This pins requirements.txt provided by zephyr-nix.pythonEnv.
    zephyr = {
      url = "github:zmkfirmware/zephyr/v3.5.0+zmk-fixes";
      flake = false;
    };
    # Zephyr sdk and toolchain.
    zephyr-nix = {
      url = "github:urob/zephyr-nix";
      inputs = {
        zephyr.follows = "zephyr";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      zmk-nix,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        rec {
          default = firmware;

          firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
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
          };

          flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
          update = zmk-nix.packages.${system}.update;

          layoutImage =
            let
              # keymap-drawer = import ./keymap-drawer.nix { inherit pkgs lib; };
              keymap-drawer = pkgs.python3Packages.callPackage ./nix/keymap-drawer.nix { };
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

      devShells = forAllSystems (

        system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          zephyr = inputs.zephyr-nix.packages.${system};
          keymap_drawer = pkgs.python3Packages.callPackage ./nix/keymap-drawer.nix { };
        in
        {
          zmk-nix-shell = zmk-nix.devShells.${system}.default;
          default = pkgs.mkShellNoCC {
            packages = [
              zephyr.pythonEnv
              (zephyr.sdk-0_16.override { targets = [ "arm-zephyr-eabi" ]; })

              pkgs.cmake
              pkgs.dtc
              pkgs.gcc
              pkgs.ninja

              pkgs.just
              pkgs.yq # Make sure yq resolves to python-yq.

              keymap_drawer

              # -- Used by just_recipes and west_commands. Most systems already have them. --
              # pkgs.gawk
              # pkgs.unixtools.column
              # pkgs.coreutils # cp, cut, echo, mkdir, sort, tail, tee, uniq, wc
              # pkgs.diffutils
              # pkgs.findutils # find, xargs
              # pkgs.gnugrep
              # pkgs.gnused

              # nix
              pkgs.nixd
              pkgs.nixfmt-rfc-style
            ];

            shellHook = ''
              export ZMK_BUILD_DIR=$(pwd)/.build;
              export ZMK_SRC_DIR=$(pwd)/zmk/app;
            '';
          };
        }
      );

    };
}
