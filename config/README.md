https://github.com/zmkfirmware/zmk/blob/main/app/boards/shields/cradio/README.md


# Research
- https://github.com/urob/zmk-helpers
- https://github.com/urob/zmk-config
- https://gist.github.com/urob/68a1e206b2356a01b876ed02d3f542c7

# How to rename

https://www.answeroverflow.com/m/1307444107098062938

Yes, so it looks like the CONFIG_ZMK_KEYBOARD_NAME in corne.conf is the right variable to be setting. Just needed to reset both boards first with your settings_reset.uf2 for it to take effect.
For those coming here looking for a tl;dr version of the solution:

1. Make sure /config/corne.conf has CONFIG_ZMK_KEYBOARD_NAME variable set

# Name the keyboard

CONFIG_ZMK_KEYBOARD_NAME="David's Corne"
...

# Other settings

2. Create a reset firmware by editing build.yaml:

```
# For simple board + shield combinations, add them
# to the top level board and shield arrays, for more
# control, add individual board + shield combinations to
# the `include` property, e.g:
#
# board: [ "nice_nano_v2" ]
# shield: [ "corne_left", "corne_right" ]
# include:
#   - board: bdn9_rev2
#   - board: nice_nano_v2
#     shield: reviung41
#
---
include:
  - board: nice_nano_v2
    shield: corne_left nice_view_adapter nice_view
  - board: nice_nano_v2
    shield: corne_right nice_view_adapter nice_view
  - board: nice_nano_v2
    shield: settings_reset
```

3. Load settings_reset-nice_nano_v2-zmk.uf2 onto both boards
4. Load corne_left nice_view_adapter nice_view-nice_nano_v2-zmk.uf2 onto left board
5. Load corne_right nice_view_adapter nice_view-nice_nano_v2-zmk.uf2 onto right board
6. Done!
