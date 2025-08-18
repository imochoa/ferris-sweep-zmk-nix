{
  python3Packages,
  runCommand,
  inkscape,
}:
let
  keymap-drawer = python3Packages.callPackage ./keymap-drawer.nix { };
in
runCommand "layout"
  {
    nativeBuildInputs = [
      keymap-drawer
      inkscape
    ];
  }
  ''
    mkdir -p $out

    # Pointing to the nix store directly would change the name!
    # BUT THE FILENAME IS IMPORTANT!
    ln -s ${../config} config

    # ${keymap-drawer}/bin/keymap
    # Generate keymap.yaml
    DRAWER_CONF="$out/keymap-drawer-config.yaml"
    LAYOUT_SVG="$out/layout.svg"
    keymap parse --columns 10 --zmk-keymap "config/cradio.keymap" > "''${DRAWER_CONF}"

    # Use it to output SVG
    keymap draw "''${DRAWER_CONF}" > "''${LAYOUT_SVG}"

    # # inkscape is quite fat... but it works
    # not on macOS!
    # inkscape "''${LAYOUT_SVG}" --export-filename="$out/layout.pdf"
    # inkscape "''${LAYOUT_SVG}" --export-filename="$out/layout.png"
  ''
