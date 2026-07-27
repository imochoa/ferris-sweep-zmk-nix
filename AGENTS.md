# AGENTS.md — ferris-sweep-zmk-nix2

ZMK firmware config for a Ferris Sweep / `cradio` split keyboard (36→34-key,
`nice_nano` / nRF52840). Unlike `ergogenesis` (a custom shield), this repo rides
the **built-in `cradio` shield** in ZMK, so `config/` is mostly just a keymap.

There are **two build paths**:
- **devcontainer** (podman + `just`) — the actively-maintained path, currently on
  **ZMK `main` / Zephyr 4.1** (same setup as `ergogenesis/firmware`). This is what
  produces the repo-root `*-nice_nano-zmk.uf2` files.
- **Nix** (`flake.nix` via `zmk-nix`) — a reproducible alternative that still pins
  the **older ZMK v0.x / Zephyr 3.5** stack and board `nice_nano_v2` (NOT migrated).
  See the divergence note below.

## Layout

```
.
├── config/                 ZMK keymap + build config (the west manifest root)
│   ├── west.yml            west manifest (pins ZMK main @ a fixed commit → Zephyr 4.1)
│   ├── cradio.conf         Kconfig for the cradio shield build
│   ├── cradio.keymap       keymap layers + combos + behaviors
│   ├── settings_reset.conf storage backend for the settings_reset image (see gotchas)
│   ├── 34.h                key-position label macros
│   └── helper.h            combo/macro helper macros
├── build.yaml              GitHub-Actions matrix: cradio_left / cradio_right / settings_reset
├── .devcontainer/          podman devcontainer (Dockerfile, devcontainer.json, scripts)
├── .just/
│   ├── in-devc.just        recipes that run INSIDE the container (west, build)
│   ├── flash.just          host-side flashing recipes
│   ├── draw.just           keymap-drawer recipes
│   └── wip/                scratch / old recipes (reference only)
├── justfile                host recipes (run via `just <recipe>` from repo root)
├── flake.nix / flake.lock  Nix build path (zmk-nix) — OLD 3.5 stack, see note
├── nix/                    Nix package/derivation helpers
├── generic-build.sh        standalone container build via build.yaml (reference)
├── local-build.{sh,py}     scratch/reference build helpers
├── zmk/ zephyr/ modules/ optional/ tools/ .west/ .build/   west-managed (gitignored)
└── *-nice_nano-zmk.uf2     built firmware outputs
```

## Building (devcontainer path)

Run from the repo root:

```bash
just devc-up                # start the devcontainer (builds image if needed)
just west-init              # one-time: west init --local config
just west-update            # one-time (slow): clone zmk + zephyr + modules
# build a target (board shield snippet cmake_args artifact_name [pristine]):
just generic-build nice_nano cradio_left  studio-rpc-usb-uart -DCONFIG_ZMK_STUDIO=y cradio_left-nice_nano-zmk
just generic-build nice_nano cradio_right studio-rpc-usb-uart -DCONFIG_ZMK_STUDIO=y cradio_right-nice_nano-zmk
just generic-build nice_nano settings_reset "" "" settings_reset-nice_nano-zmk
```

`generic-build` is **incremental by default** (reuses the build dir — seconds for
keymap edits). Pass a non-empty 6th arg for a one-off clean `--pristine` build;
do that after changing `.conf`, `west.yml`, `-D` flags, or the board/snippet.
`build.yaml` is the source of truth for the target matrix (used by CI / the
standalone `generic-build.sh`).

## How the devcontainer works (macOS podman)

- `--userns=keep-id:uid=1000,gid=1000` maps container uid 1000 to the host user
  (macOS uid 501) so bind-mounted dirs are writable.
- Named podman volumes are NOT used — on macOS they end up owned by unmapped uid
  999 that the container can't write to. Everything is a bind mount.
- `west-update` runs `git config --global --add safe.directory "*"` before
  `west update` (bind-mounted repos are host-owned → git "dubious ownership").

## ZMK main / Zephyr 4.1 + HWMv2 `nice_nano` gotchas

Board is **`nice_nano`** (NOT `nice_nano_v2` — HWMv2 rename; the old name errors).
The HWMv2 board defconfig is minimal and DROPS defaults the old board provided,
so `config/cradio.conf` sets them explicitly (learned the hard way):

- `CONFIG_ZMK_BLE=y` — else USB-only, no Bluetooth.
- `CONFIG_FLASH=y` + `CONFIG_FLASH_MAP=y` + `CONFIG_NVS=y` + `CONFIG_SETTINGS_NVS=y`
  — the settings/NVS backend; without it BLE bonds don't persist (re-pair every
  power cycle).
- `CONFIG_BT_SMP_ALLOW_UNAUTH_OVERWRITE=y` + `CONFIG_ZMK_BLE_PASSKEY_ENTRY=n`
  — Just Works pairing (no PIN) that overwrites stale bonds on re-pair.
- `config/settings_reset.conf` re-adds the FLASH/NVS backend so the built-in
  `settings_reset` image can actually erase bonds (HWMv2 no longer provides it —
  otherwise flashing settings_reset is a silent no-op).
- `config/west.yml` sets `group-filter: [-optional]` to stop west fetching
  Zephyr's optional modules (tflite-micro, thrift) into `optional/`.
- `.just/in-devc.just`: `west-update` no longer runs `west zephyr-export` (fails
  with a `zcmake` import error on the 4.1 image, not needed); `hard-rmdirs` fully
  wipes `zephyr/` incl. `.git` (a leftover `.git` leaves the 3.5→4.1 checkout
  half-populated) and removes `optional/`.
- `zmk-helpers` (urob) is pinned in `west.yml` but currently unused by the keymap
  (its `#include` is commented out).

## Nix path (divergence)

`flake.nix` + `nix/lilyinstarlight-zmk-package.nix` build via `zmk-nix`, still
pinned to **Zephyr `v3.5.0+zmk-fixes`, ZMK v0.x, board `nice_nano_v2`** — it was
NOT migrated with the devcontainer path. So the two paths currently target
different ZMK/Zephyr versions. If you rely on the Nix build, migrate it
separately (bump the zephyr input to 4.1, board to `nice_nano`, and the
`zephyrDepsHash`).

## Conventions

- Built `.uf2` files land at the repo root; regenerate with the `generic-build`
  recipes above.
- `zmk/`, `zephyr/`, `modules/`, `optional/`, `.build/`, `.west/`, `tools/` are
  gitignored (west-managed or build artifacts). Do not hand-edit them.
- Keep this in sync with `ergogenesis/firmware/AGENTS.md` — the devcontainer
  setup and HWMv2 gotchas are shared between the two repos.
