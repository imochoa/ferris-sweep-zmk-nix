# ToDos

## Better bootloader
```
// To flash:
// 2x reset OR Bootloader 
```

## Tap-Dance currency
```
        // td_currency: td_currency {
        //     compatible = "zmk,behavior-tap-dance";
        //     label = "TAPDANCE Currency";
        //     #binding-cells = <0>;
        //     tapping-term-ms = <150>;
        //     // quick-tap-ms = <0>;
        //     // flavor="tap-preferred";
        //     bindings = <&kp DOLLAR>, <&euro_macro>;
        // };
```

## Smart numlock
/ auto-layer https://github.com/urob/zmk-auto-layer
// switch out of a layer automatically when pressing an unrelated key (e.g. number layer when not pressing a num)

# Behaviours
```
// |  {{{1 Behaviors
// https://zmk.dev/docs/keymaps/behaviors#key-press-behaviors
// https://zmk.dev/docs/keymaps/behaviors#user-defined-behaviors
    behaviors {
        // [if HELD] if PRESSED {TAPPED}
        // key press &kp KEY
        // tap dance &td0 KEY1 KEY2 KEY3
        // mod-tap &mt [MODIFIER] KEY
        // layer-tap &lt [LAYER] KEY
        // momentary layer &mo [LAYER]
        // to layer &to LAYER
        // toggle layer &tog LAYER
        // sticky key &sk MODIFIER
        // sticky layer &sl LAYER
        // Original ht
        // ht: hold_tap {
        //     compatible = "zmk,behavior-hold-tap";
        //     #binding-cells = <2>;
        //     flavor = "tap-preferred";
        //     tapping-term-ms = <220>;
        //     quick-tap-ms = <150>;
        //     require-prior-idle-ms = <100>;
        //     bindings = <&kp>, <&kp>;
        // };
        ht: hold_tap {
            compatible = "zmk,behavior-hold-tap";
            #binding-cells = <2>;
            // flavor = "tap-preferred";
            flavor = "balanced";
            tapping-term-ms = <220>;
            quick-tap-ms = <150>;
            require-prior-idle-ms = <100>;
            bindings = <&kp>, <&kp>;
        };
        td0: tap_dance_0 {
            compatible = "zmk,behavior-tap-dance";
            label = "TAPDANCE";
            #binding-cells = <0>; // No inputs
            tapping-term-ms = <200>;
            bindings = <&kp N1>, <&kp N2>, <&kp N3>; // outputs
        };
        // td_currency: td_currency {
        //     compatible = "zmk,behavior-tap-dance";
        //     label = "TAPDANCE Currency";
        //     #binding-cells = <0>;
        //     tapping-term-ms = <150>;
        //     // quick-tap-ms = <0>;
        //     // flavor="tap-preferred";
        //     bindings = <&kp DOLLAR>, <&euro_macro>;
        // };
        // https://zmk.dev/docs/keymaps/behaviors/hold-tap?examples=home_row_mods#layer-tap
        /* urob timeless HRM */
        /* Left-hand HRMs. */
        hml: hml {
            compatible = "zmk,behavior-hold-tap";        
            #binding-cells = <2>;
            flavor = "balanced";
            // tapping-term-ms = <280>;
            // quick-tap-ms = <175>;
            // require-prior-idle-ms = <150>;
            tapping-term-ms = <220>;
            quick-tap-ms = <150>;
            require-prior-idle-ms = <100>;
            bindings = <&kp>, <&kp>;
            hold-trigger-key-positions = <KEYS_R THUMBS>;
            hold-trigger-on-release;
        };
        /* Right-hand HRMs. */
        hmr: hmr {
            compatible = "zmk,behavior-hold-tap";        
            #binding-cells = <2>;
            flavor = "balanced";
            // tapping-term-ms = <280>;
            // quick-tap-ms = <175>;
            // require-prior-idle-ms = <150>;
            tapping-term-ms = <220>;
            quick-tap-ms = <150>;
            require-prior-idle-ms = <100>;
            bindings = <&kp>, <&kp>;
            hold-trigger-key-positions = <KEYS_L THUMBS>;
            hold-trigger-on-release;
        };
    };
```

# Combos

```
// |  {{{1 Combos
// https://zmk.dev/docs/keymaps/combos
    combos {
        compatible = "zmk,combos";
        // Keys
        // combo_esc {
        //     key-positions = <10 19>; // INPUT
        //     timeout-ms = <50>;
        //     // layers = < BAS SYM >;
        //     bindings = <&kp ESC>; // OUTPUT
        // };
        combo_windows {
            // Windows key was missing!
            key-positions = <LM1 RM1>;
            timeout-ms = <50>;
            // layers = < BAS SYM >;
            bindings = <&kp LWIN>;
        };
        combo_esc {
            // Wanted a way to avoid 2 layer switches while pressing escape in vim
            // emulates C-[
            key-positions = <LB4 RT4>;
            timeout-ms = <50>;
            // layers = < BAS SYM >;
            bindings = <&kp ESC>;
        };

        // Layers
        // gaming_layer_toggle {
        //     key-positions = <0 10 20>;
        //     timeout-ms = <50>;
        //     layers=<BAS GAM>;
        //     bindings = <&tog GAM>;
        // };
        combo_to_sys_layer {
            timeout-ms = <50>;
            key-positions = <4 14 24>;
            layers=<BAS SYS>;
            bindings = <&to SYS>;
        };
        // it's good to have a way to switch to the system layer on each half of the keyboard
        lcombo_to_sys {
            timeout-ms = <50>;
            key-positions = <LT0 LM0 LB0>;
            bindings = <&to SYS>;
        };
        rcombo_to_sys {
            timeout-ms = <50>;
            key-positions = <RT0 RM0 RB0>;
            bindings = <&to SYS>;
        };
        
        // combo_to_base_layer {
        //     timeout-ms = <50>;
        //     key-positions = <31 32>;
        //     layers=<SYM NUM SYS>;
        //     bindings = <&to BAS>;
        // };
        // rcombo_to_base {
        //     timeout-ms = <50>;
          //     key-positions = <32 6>;
        //     bindings = <&to BAS>;
        // };
        // lcombo_to_base {
        //     timeout-ms = <50>;
          //     key-positions = <31 3>;
        //     bindings = <&to BAS>;
        // };
        // rcombo_to_sym {
        //     timeout-ms = <50>;
          //     key-positions = <32 7>;
        //     bindings = <&to SYM>;
        // };
        // lcombo_to_sym {
        //     timeout-ms = <50>;
          //     key-positions = <31 2>;
        //     bindings = <&to SYM>;
        // };
        // rcombo_to_num {
        //     timeout-ms = <50>;
          //     key-positions = <32 8>;
        //     bindings = <&to NUM>;
        // };
        // lcombo_to_num {
        //     timeout-ms = <50>;
          //     key-positions = <31 1>;
        //     bindings = <&to NUM>;
        // };
        // rcombo_to_nav {
        //     timeout-ms = <50>;
          //     key-positions = <32 9>;
        //     bindings = <&to NAV>;
        // };
        // lcombo_to_nav {
        //     timeout-ms = <50>;
          //     key-positions = <31 0>;
        //     bindings = <&to NAV>;
        // };
        //
        // combo_to_sym_layer {
        //     timeout-ms = <50>;
        //     key-positions = <31 33>;
        //     layers = <BAS NUM>;
        //     bindings = <&to SYM>;
        // };
        // combo_to_num_layer {
        //     timeout-ms = <50>;
        //     key-positions = <30 32>;
        //     layers = <BAS SYM>;
        //     bindings = <&to NUM>;
        // };
    };
```


# Macros

```
// |  {{{1 Macros
// https://zmk.dev/docs/keymaps/behaviors/macros
    macros {
        dodgeslide: dodgeslide { // space 40ms wheeldown 15ms wheel up space 50ms e down 150 ms e up
            label = "Darktide Dodge Slide";
            compatible = "zmk,behavior-macro";
            #binding-cells = <0>; // Number of arguments
            wait-ms = <40>;
            bindings
                = <&macro_tap &kp TAB>
                , <&macro_wait_time 200>
                , <&macro_tap &kp LCTRL>
                ;
        };

        // // 2 params macro
        // my_two_param_macro: my_two_param_macro {
        //     // ...
        //     compatible = "zmk,behavior-macro-two-param";
        //     #binding-cells = <2>; // Must be 2
        //     bindings = /* ... */;
        // };

        // Unicode keys
        // https://askubuntu.com/questions/1171633/i-can-use-alt-x-to-enter-unicode-on-an-old-machine-how-is-this-possible
        euro_macro: euro_macro {
            label = "euro macro";
            compatible = "zmk,behavior-macro";
            #binding-cells = <0>;
            bindings
                    = <&macro_press   &kp LCTRL>
                    , <&macro_press   &kp LSHFT>
                    , <&macro_tap     &kp U &kp N2 &kp N0 &kp A &kp C &kp ENTER >
                    , <&macro_release &kp LCTRL>
                    , <&macro_release &kp LSHFT>
                    ;
        };
    };
```

# Keymap

```
// |  {{{1 Keymap
    keymap {
        compatible = "zmk,keymap";
        // {{{1 LAYER 0 -> BAS
        default_layer { 
            display-name = "Base";
            bindings = <
            &kp Q           &kp W        &kp E        &kp R         &kp T     /* | */    &kp Y      &kp U         &kp I         &kp O        &kp P
            &hml LSHIFT  A  &hml LALT S  &hml LCTRL D &hml LGUI  F  &kp G     /* | */    &kp H      &hmr RGUI  J  &hmr RCTRL K  &hmr RALT  L &hmr RSHIFT SEMI
            &kp Z           &kp X        &kp C        &kp V         &kp B     /* | */    &kp N      &kp M         &kp COMMA     &kp DOT      &kp FSLH
                                                      &lt 1 BKSP    &kp DEL   /* | */    &kp TAB    &lt 2 SPACE
 
            >; // kinesis has enter where I put tab
        };

        // {{{1 LAYER 1 -> SYM
        // TODO: put unused keys in <24> <25> (e.g. ^ %)
        symbols_layer {
            display-name = "Symbols";
            bindings = <
            &kp ESC           &kp AT          &kp HASH       &kp DOLLAR      &kp PRCNT   /* | */    &kp CARET &kp AMPS       &kp STAR         &mt UNDER MINUS   &none
            &hml LSHIFT  1    &hml LALT GRAVE &hml LCTRL SQT &hml LGUI EQUAL &none       /* | */    &none     &hmr RGUI LPAR &hmr RCTRL RPAR  &hmr RALT BSLH    &hmr RSHIFT ENTER
            &kp EXCL          &none           &kp LEFT       &kp RIGHT       &none       /* | */    &none     &kp UP         &kp DOWN         &kp LBKT          &kp RBKT 
                                                             &trans         &trans       /* | */    &trans    &trans
            >;
        };
        // smart number layer?
        // {{{1 LAYER 2 -> NUM
        // F1 - F24
        num_layer {
            display-name = "Numbers";
            bindings = <
              &kp ESC          &none           &none            &none           &none      /* | */   &kp MINUS    &kp N7       &kp N8        &kp N9          &kp BKSP
              &hml LSHIFT TAB  &hml LALT HASH  &hml LCTRL HASH  &hml LGUI HASH  &kp EQUAL  /* | */   &none        &hmr RGUI N4 &hmr RCTRL N5 &hmr RALT  N6   &hmr RSHIFT ENTER
              &none            &none           &none            &none           &to NAV    /* | */   &kp N0       &kp N1       &kp N2        &kp N3          &kp N0
                                                                &trans          &trans     /* | */   &trans     &trans
              >;
        };
        // TODO: fn layer?

        // {{{1 LAYER 3
         nav_layer {
             display-name = "Nav";
             bindings = <
               &kp N1       &kp N2  &kp N3  &kp N4      &kp N5  /* | */    &none       &none      &none       &none        &kp BKSP
               &kp LSHIFT   &kp Q   &kp W   &kp E       &kp R   /* | */    &kp LEFT    &kp DOWN   &kp UP      &kp RIGHT    &kp ENTER
               &kp LCTRL    &kp A   &kp S   &kp D       &kp G   /* | */    &none       &kp UP     &kp DOWN    &none        &none
                                            &kp SPACE   &none   /* | */    &none       &to BAS
             >;
         };
         // TODO: get the navigation commands from ben
        
        // {{{1 LAYER 4
        sys_layer {
          // Don't need &sys_reset, right?
            display-name = "System";
            bindings = <
            &studio_unlock &bootloader   &none        &none         &none   /* | */    &none   &none         &none         &bootloader   &studio_unlock 
            &bt BT_SEL 3   &bt BT_SEL 2  &bt BT_SEL 1 &bt BT_SEL 0  &none   /* | */    &none   &bt BT_SEL 0  &bt BT_SEL 1  &bt BT_SEL 2  &bt BT_SEL 3
            &bt BT_CLR     &none         &none        &none         &none   /* | */    &none   &none         &none         &none         &bt BT_CLR
                                                      &none         &none   /* | */    &none   &to BAS 
            >;
        };

        // {{{1 LAYER 5

        // // {{{1 LAYER 6
        // gaming_layer {
        //     display-name = "Gaming";
        //     bindings = < 
        //     &kp N1    &kp N2 &kp N3 &kp N4      &kp N5       &trans &trans &trans &trans &trans
        //     &kp LSHFT &kp A  &kp W  &kp D       &kp R        &trans &trans &trans &trans &trans 
        //     &kp LCTRL &kp G  &kp S  &kp E       &kp F        &trans &trans &trans &trans &trans 
        //                             &dodgeslide &kp SPACE    &trans &trans
        //     >; // &mkp MB3 // mouse button 3
        // };
    };
};

// {{{1 Reference

// &trans &trans &trans &trans &trans &trans &trans &trans &trans &trans
// &trans &trans &trans &trans &trans &trans &trans &trans &trans &trans 
// &trans &trans &trans &trans &trans &trans &trans &trans &trans &trans 
//                      &trans &trans &trans &trans

```

# References
- https://github.com/urob/zmk-helpers/raw/main/docs/img/key_labels_example.png
- https://peccu.github.io/zmk-cheat-sheet/
- https://franknoirot.co/posts/ferris-sweep-keyboard-layout
- https://github.com/benvallack/zmk-config/blob/master/config/cradio.keymap
- https://zmk.dev/docs/keymaps/list-of-keycodes
