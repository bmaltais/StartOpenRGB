# StartOpenRGB

An Omarchy shell plugin (QML) that sets RGB colours through OpenRGB. `bin/startopenrgb` is the CLI and does all the work; `Service.qml` owns the window and the IPC and only calls the CLI. Same rules as the other Start apps (see `scripts/devkit/docs/ui-standards.md`): follow the theme, no hard-coded colours except the colour presets.

- Test UI changes in the nested session, never on the real lights: `scripts/dev up`, `open`, `shot FILE`, `errors` (0 = clean), `reload` after an edit, `down` at the end. It sets `STARTOPENRGB_DEMO=1`. Click pixels are those of the session (`dev --help`), which can differ from a screenshot's size: calibrate with `dev move` first.
- Fake a missing OpenRGB in the session with `touch $XDG_RUNTIME_DIR/startopenrgb-dev/nest/home/.config/startopenrgb/demo-missing`.
- Run `shellcheck bin/startopenrgb` before committing. Commits go on a branch, never `main`.
- Not verified on real hardware beyond `openrgb --list-devices` and `--color` on the author's machine; the real install path (terminal + sudo) has not been exercised.
- `startopenrgb serve` (run by the plugin) owns the OpenRGB server; without a server `state` lists no devices on purpose, because a plain `openrgb --list-devices` probes the hardware for ~55 s.
