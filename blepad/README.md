# Right half as a glasses pad (BLE, not a keyboard)

An alternative firmware for the Sweep's right half: it becomes an 8-key pad
for an Even G2 glasses setup built on Ben Vallack's tools. The half does not act
as a keyboard. Ben's 4 Key pad firmware streams raw key press/release events
over a custom Bluetooth GATT service. His companion phone app turns those into
taps, holds and chords and sends them to the glasses server. A keyboard's keys
go to the phone's OS; these events reach the app even while the phone is locked.

That firmware lives in Ben's members-only repo (`4key-macropad`,
`ble-firmware/`). This repo holds only the Sweep's pin map and the build
recipes; nothing of Ben's is committed here.

| File | What |
|---|---|
| `sweep-right.overlay` | eight right-half keys, on top of the firmware's own overlay |
| `../justfile` `blepad-build` | copies a local checkout into `.build/`, widens the accepted key codes from 1-5 to 1-8, builds in the devcontainer |
| `../.just/flash.just` `blepad` | flashes the result |

## Keys

Positions as the phone app numbers them (key index + 1):

```
 .  1  2  8  .        (top row: index, middle, ring)
 .  3  4  7  .        (home row: index, middle, ring)
 .  .  .  .  .
       5  6           (thumbs: inner, outer)
```

1-4 form a 2x2 in the same order as Ben's 2x2 pad, so bindings made for it
apply unchanged. 5, the inner thumb, matches his pad's trigger key. Change the
choice in `sweep-right.overlay`; the pin of every right-half key is listed at
its top.

## Build and flash

Needs a `4key-macropad` checkout (default `~/Code/glasses/4key-macropad`, or
set `BLEPAD_SRC`) and the devcontainer set up as in `AGENTS.md`.

```sh
just blepad-build              # -> firmware/sweep-right-blepad-debug.uf2
just blepad-build release      # -> firmware/sweep-right-blepad-release.uf2
just flash blepad              # double-tap reset on the RIGHT half
```

Back to the keyboard: flash `cradio_right-nice_nano-zmk.uf2` to the right half
(`just flash firmware` does both halves). The left half is the ZMK central and
keeps working alone while the right half is a pad. Re-pairing the halves
afterwards may need `just flash reset-firmware` on both.

Ben uses the debug build day to day because his release build sometimes fails
to wake from soft sleep, so `debug` is the default.

## Limits

- The firmware has no pairing or bonding yet: any phone nearby can connect.
- The phone apps use one digit per key, so keys 6-8 already send positions
  `6`-`8`. After a reconnect or a dropped event, though, they rebuild the held
  keys from keys 1-5 only, so a chord involving keys 6-8 can be lost at that
  moment. It's a one-line range change in the app.
- Positions 6-8 need bindings on the glasses server before they do anything.
