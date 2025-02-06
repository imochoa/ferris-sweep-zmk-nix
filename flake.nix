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
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = nixpkgs.lib;
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
            ];

            board = "nice_nano_v2";
            shield = "cradio_%PART%";

            enableZmkStudio = true;
            # TODO: make a PR to fix this CMake flag...
            extraCmakeFlags = [ "-DCONFIG_ZMK_STUDIO=y" ];

            zephyrDepsHash = "sha256-YvzRxhwUR5bZqToXMwhfLp+ewxgiQHrSgPUVHBpnOA4=";

            meta = {
              description = "ZMK firmware";
              license = nixpkgs.lib.licenses.mit;
              platforms = nixpkgs.lib.platforms.all;
            };
          };

          flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
          update = zmk-nix.packages.${system}.update;

          layoutImage =
            let
              # /home/imochoa/Code/ferris-sweep-zmk-nix/flake.nix
              # https://nixos.org/manual/nixpkgs/stable/#sec-language-go
              py-tree-sitter-devicetree = pkgs.python3Packages.buildPythonPackage rec {
                name = "tree-sitter-devicetree";
                version = "v0.12.1";

                src = pkgs.fetchFromGitHub {
                  owner = "joelspadin";
                  repo = "${name}";
                  rev = "${version}";
                  sha256 = "sha256-UVxLF4IKRXexz+PbSlypS/1QsWXkS/iYVbgmFCgjvZM=";
                };

                pyproject = true;
                build-system = [
                  # pkgs.python3Packages.poetry-core
                  pkgs.python3Packages.setuptools
                  # pkgs.python3Packages.wheel
                ];
                # doCheck = false;
              };
              # NixPkgs does not offer `keymap-drawer` as a python package nor a
              # stand-alone application, so we have  pull the package into our environment
              keymap-drawer = pkgs.python3Packages.buildPythonPackage rec {
                name = "keymap-drawer";
                version = "v0.20.0";

                src = pkgs.fetchFromGitHub {
                  owner = "caksoylar";
                  repo = "${name}";
                  rev = "main";
                  sha256 = "sha256-bNXx1JwzzJUROBXtR7jxuNFrC6uKFADp0dzJ00s3O7o=";
                };

                pyproject = true;
                build-system = [
                  pkgs.python3Packages.poetry-core
                  # pkgs.python3Packages.setuptools
                  # pkgs.python3Packages.wheel
                ];

                nativeBuildInputs = [
                  # pkgs.python3Packages.poetry-core
                  # pkgs.tree-sitter
                  # pkgs.tree-sitter-grammars.tree-sitter-devicetree
                  # py-tree-sitter-devicetree
                ];

                doCheck = false;

                propagatedBuildInputs =
                  with pkgs.python3Packages;
                  [
                    pcpp
                    platformdirs
                    pydantic
                    pydantic-settings
                    pyparsing
                    pyyaml
                    tree-sitter
                  ]
                  ++ [
                    py-tree-sitter-devicetree
                    # pkgs.tree-sitter
                    # py-tree-sitter-devicetree
                    # pkgs.tree-sitter-grammars.tree-sitter-devicetree
                  ];
                # meta = {
                #   homepage = "https://github.com/caksoylar/keymap-drawer";
                #   description = "Visualize keymaps that use advanced features like hold-taps and combos, with automatic parsing ";
                #   license = lib.licenses.mit;
                # };
              };
              zmkfirmwareRepo = pkgs.fetchFromGitHub {
                owner = "zmkfirmware";
                repo = "zmk";
                rev = "v0.1.0";
                sha256 = "sha256-kA/4Ad17/qP1p7ugf9mA9hE+7An9m1248JAb0f9CJe4=";
              };
            in
            pkgs.runCommand "layout" { } ''
              mkdir -p $out

              # ln -s ${zmkfirmwareRepo} zmk
              # ln -s ${zmkfirmwareRepo} $out/zmk
              # ${lib.getBin keymap-drawer}/bin/keymap parse -h > $out/help.txt
              # ${keymap-drawer}/bin/keymap dump-config > $out/config.yaml

              # Pointing to the nix store directly would change the name!
              # BUT THE FILENAME IS IMPORTANT!
              ln -s ${./config} config

              # Generate keymap.yaml
              DRAWER_CONF="$out/keymap-drawer-config.yaml"
              LAYOUT_SVG="$out/layout.svg"
              ${keymap-drawer}/bin/keymap parse --columns 10 --zmk-keymap "config/cradio.keymap" > "''${DRAWER_CONF}"

              # Use it to output SVG
              ${keymap-drawer}/bin/keymap draw "''${DRAWER_CONF}" > "''${LAYOUT_SVG}"

              # inkscape is quite fat... but it works
              ${pkgs.inkscape}/bin/inkscape "''${LAYOUT_SVG}" --export-filename="$out/layout.pdf"
              ${pkgs.inkscape}/bin/inkscape "''${LAYOUT_SVG}" --export-filename="$out/layout.png"
            '';

        }
      );

      devShells = forAllSystems (system: {
        default = zmk-nix.devShells.${system}.default;
      });

      # Pre-commit?

    };
}
