{
  pkgs,
  lib,
  ...
}:
let
  # (not in nixpkgs)
  py-tree-sitter-devicetree = pkgs.python3Packages.buildPythonPackage rec {
    name = "tree-sitter-devicetree";
    version = "v0.14.1";
    src = pkgs.fetchFromGitHub {
      owner = "joelspadin";
      repo = "${name}";
      rev = "${version}";
      sha256 = "sha256-ua+mk++93ooH5nQH/M4vj7VSSvVDis/Uh8S1H34TxKs=";
    };
    pyproject = true;
    build-system = [ pkgs.python3Packages.setuptools ];
    # metadata?
  };
  # (not in nixpkgs)
  keymap-drawer = pkgs.python3Packages.buildPythonPackage rec {
    name = "keymap-drawer";
    version = "v0.21.0";
    src = pkgs.fetchFromGitHub {
      owner = "caksoylar";
      repo = "${name}";
      rev = "main";
      sha256 = "sha256-LySpE9HFs2LnYgH/sOK1KOgkLuXTQyo0fEbir2mgxyI=";
    };
    pyproject = true;
    build-system = [ pkgs.python3Packages.poetry-core ];
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
      ++ [ py-tree-sitter-devicetree ];
    meta = {
      homepage = "https://github.com/caksoylar/keymap-drawer";
      description = "Visualize keymaps that use advanced features like hold-taps and combos, with automatic parsing ";
      license = lib.licenses.mit;
    };
  };
in
keymap-drawer
