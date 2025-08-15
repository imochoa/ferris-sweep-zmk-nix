# NEVER HOTSWAP TRRS CABLES!
> ONLY INSERT/REMOVE THEM WHEN THE BOARD IS COMPLETELY OFF


# ZMK

- format with https://github.com/mskelton/dtsfmt?
- https://github.com/benvallack/zmk-config-piano/blob/main/config/boards/shields/piano/piano.keymap
- https://peccu.github.io/zmk-cheat-sheet/

## [Adding ZMK Studio Support](https://zmk.dev/docs/features/studio#adding-zmk-studio-support-to-a-keyboard)

> Firmware with ZMK Studio enabled require significantly more RAM. Some MCUs, such as the STM32F072 series, will require fine tuning of various settings in order to reduce the RAM consumption enough for a Studio enabled build to fit.

The keyboard:

1. ✅ **NEEDS** to have a physical layout with the `keys` property defined
2. ?? **SHOULD NOT** have a `chosen` `zmk,matrix-transform`

   > Relevant information can in:
   >
   > - [The dedicated page on physical layouts -> how to create one](https://zmk.dev/docs/development/hardware-integration/physical-layouts)
   > - [The new shield guide -> informing you how to select a physical layout once defined](https://zmk.dev/docs/development/hardware-integration/new-shield)
   > - [The corresponding configuration page, for reference](https://zmk.dev/docs/config/layout#physical-layout)

3. **NEEDS** to be configured to allow CDC-ACM console snippets (this is also used for [ USB logging ](https://zmk.dev/docs/development/usb-logging)) to use the studio-rpc-usb-uart snippet,

   - If your keyboard is a composite keyboard, consisting of an in-tree board and a shield, then you can skip this step as the board will already be configured properly.
   - Relevant information on that can be found [ in the Zephyr documentation ](https://docs.zephyrproject.org/3.5.0/snippets/cdc-acm-console/README.html).

4. build and tested firmware with ZMK Studio enabled
5. ✅ Add the `studio` flag to your [ keyboard's metadata ](https://zmk.dev/docs/development/hardware-integration/hardware-metadata-files#features).

### [Other ref](https://github.com/mctechnology17/zmk-config?tab=readme-ov-file#zmk-studio)

- For zmk-studio it is necessary to enable the &studio_unlock macro but you can skip this if you use CONFIG_ZMK_STUDIO_LOCKING=n in your zmk configuration. This is enabled by default in this repository.
- Remember that this has to be activated on the master and the dongle: snippet: studio-rpc-usb-uart
- with the cmake-args: -DCONFIG_ZMK_USB=y flag you can activate the master (dongle or central) to connect always defaults to usb.
- The zmk-studio only connects with USB on the web and only BLE in the app, it is useful to have a toggle key to switch between BLE and USB. (this is what I understood, if not, please correct me)

# References

## [lostgent/sweep-config](https://github.com/lostgent/sweep-config)

### Design principles

1.  **Every key should have just one way to type it**, the only exception is the `SHIFT` key that is both available as a HR mod behind a layer and a thumb key.

2.  **Avoid hold-taps** as they are finnicky to tweak, could misfire or require long pauses. Same reasons pointed by Callum at [his readme](https://github.com/qmk/qmk_firmware/blob/master/users/callum/readme.md) apply here. An _excecption_ was made to accomodate `GLOBE` in both `DEF` and `NAV` layers, at the `Z` key position. This allows me to trigger my window manager of choice ([Swish](https://highlyopinionated.co/swish/)) on macOS as well as use iPadOS shorcuts. There's also a &lt hidden in the `NWD` layer to allow for triggering `SYM` form there on hold and cancelling `&numword` when tapped.
3.  **Thumbs do all the regular layer changes**. Except for `&smart_mouse` and `&numword`, that are toggled by combos.

4.  **Keyboard functionality** (such as `&bootloader` and bluetooth toggles) is **hidden behind combos** available only in the `FUN` layer. This makes them _purposelly difficult_ to trigger by accident, while still being still being accessible when needed;

5.  **Combos** should be _convenience only_, such as:

    - NAV layer toggle for extended edits (`left thumb keys`);
    - mute (`vol up and down` on `NAV`); and
    - left hand activation of some special keys (`ENTER`, `BACKSPACE`, `SPACE` and `ESCAPE`).

6.  **Tap dance** is used to make double press on thumb `shift` trigger `&caps_word` behavior and to combine `next song` and `previous song` into the same key on `NAV`.

### My use case and layer design choices

Its main uses are writing prose in both English and Portuguese as well as some very light coding.

#### 1. QWERTY with changes on `'` `;` and `/` keys positions

Base layout is QWERTY with a few changes to optimize for my use case.

- On `DEF`, `;` was moved down and made way to `'` as this is far more useful to make accents and quotes in my use cases.
- `/` exists in the `SYM` layer.

#### 2. Long `&sk` timeouts and `&lc` for cancelling queued mods when triggering other layers

A crazy long timeout (1000m) was assigned to `&sk` behavior in this keymap. So there's no rush to combine mods with keycodes with keys from `DEF` or whatever the currently active layer.

Layer keys (usually `&mo`) were replaced by a custom layer-cancel macro (`&lc`) that taps a `&kp K_CANCEL` command alongside the `&mo` command. This workaround cancels any previoulsy `&sk` queued mods on the layer key press.

This design allows for _canceling_ mods only when invoking `SYM`, `NAV`, of `FUN`, while still _keep them triggered_ when you move back to `DEF`.

This emulates in ZMK the `LA_NAV` and `LA_SYM` custom behaviors found in [Callum's QMK keymap](https://github.com/qmk/qmk_firmware/blob/master/users/callum/readme.md).

It's built with the [parametrized macros](https://zmk.dev/docs/behaviors/macros#parameterized-macros) as `&lc` to allow for easier reading of the keymap and user modification.

#### 3. `&swapper` for swapping between apps/windows

Allows for `CMD+TAB` with just one key. It keeps the modal open until you release the layer toggle, just as you would hold `CMD` between `TAB` keypresses.

This is _not native to ZMK's `main` repo_ and requires [PR# 1366](https://github.com/zmkfirmware/zmk/pull/1366). See ZMK.dev [documentation](https://zmk.dev/docs/features/beta-testing) for instructions on how to use PRs not yet merged into ZMK's main repo.

#### 4. Numpad for `&numword`

`&numword` is accessible via `S` and `D` key combo.

This behavior allows for quick entering numbers and will disable the numpad layer upon key press of any key than a number, math symbol or `BACKSPACE`/`DELETE`. I believe this behavior was introduced to the custom mech community in QMK by [Jonas Hietala](https://www.jonashietala.se/blog/2022/09/06/the_current_t-34_keyboard_layout/#numword). This ZMK implemenation was made by [urob](https://github.com/urob/zmk-config#numword) and I've copied with a few modifications here.

#### 5. Apple's `Globe` key on mod-tap `Z` and `;` keys

Recently ZMK implementted a [keycode](https://zmk.dev/docs/codes#application-controls) for emulating `GLOBE`/`fn` key on Apple's keyboards.

It's not 100% the same behavior made by Apple's keyboards (see limitations [here](https://github.com/zmkfirmware/zmk/pull/1938#issuecomment-1744579039)), but it gets the job done for my uses – wich is mainly window manipulation on both macOS and iPadOS. So I've made it into a `&mt` replicated in `DEF`, `NAV` and `SYM` on the keys used by lower pinkies.

#### 6. `&smart_mouse` copied from urob's repo

Yet another feature copied from [urob's repo](https://github.com/urob/zmk-config?tab=readme-ov-file#smart-mouse).

It is activated from the `M,.` key combo, from `DEF` layer.

Also requires [PR #1366](https://github.com/zmkfirmware/zmk/pull/1366) used in `&swapper` behavior.

#### 7. Left hand combos for one handed use of common action keys in combination with the mouse on the right hand

Some combos where added to make it possible to use the keyboard one handed. They're mainly for use with the left hand (so a mouse can be used on the righ hand).

- `QA` for `ESC`
- `WS` for `TAB`
- `ED` for `F18` (which I use to trigger some app-specific macros on Keyboarad Maestro)
- `RF` for `ENTER`
- `TG` for `BACKSPACE`

## https://github.com/duckyb/zmk-sweep

## https://github.com/benvallack/zmk-config/blob/master/config/cradio.keymap
