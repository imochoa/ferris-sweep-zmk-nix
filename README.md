# ZMK

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
