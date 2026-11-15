# StartOpenRGB

Set the colour of your machine's RGB lights from Omarchy. A plugin for the Omarchy shell (Quickshell/QML) that drives [OpenRGB](https://openrgb.org) through a small command-line tool.

- A window with ten preset colours, any `RRGGBB` colour, a brightness slider (it scales the colour, so it works on every device) and **Lights off**.
- The colour you choose is saved and put back at login. The plugin keeps an OpenRGB server running (OpenRGB probes the hardware for about a minute on every plain call; a server does it once), so the window and the CLI answer at once; the lights show up in the window a minute after login.
- If OpenRGB is not installed, the window offers to install it (it opens a terminal for your sudo password, installs the package and reloads udev).
- Optional bar icon: left click opens the window, right click turns the lights off.

## Use

```sh
omarchy-shell io.github.bmaltais.startopenrgb open          # toggle the window
omarchy-shell io.github.bmaltais.startopenrgb color 0000ff  # every light
omarchy-shell io.github.bmaltais.startopenrgb off
bin/startopenrgb --help                                      # the CLI the window calls
```

Install by copying this folder to `~/.config/omarchy/plugins/io.github.bmaltais.startopenrgb` (or `scripts/reload`, which copies the checkout and restarts your shell), then add the bar icon from the bar's settings if you want it.

## Limits

- One colour for all lights, set in Static (or Direct) mode. Per-device colours and effects are `startopenrgb color HEX DEVICE` and `startopenrgb mode NAME [DEVICE]` on the command line; the window does not offer them yet.
- Devices OpenRGB cannot see are not shown. Some need the `i2c-dev` kernel module or udev rules (the package ships them).

## Development

`scripts/devkit` is a git submodule of [omarchy-plugin-devkit](https://github.com/bmaltais/omarchy-plugin-devkit): clone with `--recurse-submodules`. `scripts/dev up` starts a nested session with `STARTOPENRGB_DEMO=1`, which serves fixture devices and runs no `openrgb` command, so a click never touches the real lights. `scripts/dev --help` lists the rest; in the session, click pixels are the session's own size, not the screenshot's, when the two differ.
