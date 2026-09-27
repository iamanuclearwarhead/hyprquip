# hyprquip

hyprland's official splash texts, anywhere.

hyprland draws a little splash line at the bottom of its default wallpaper ("it's not awesome, it's hyprland!", "i use arch, btw", and friends). as soon as a shell like caelestia or serpantinum puts its own wallpaper on top, the splash is gone. hyprquip brings it back, and also lets you drop splashes into hyprlock, waybar, fastfetch or your terminal.

the splash list is the one in hyprland's source (`src/helpers/Splashes.hpp`), including the christmas and new year lists, with the same date rules hyprland uses.

## what you get

- **desktop splash**: a tiny quickshell overlay that sits on top of your wallpaper and below your windows, placed and sized exactly like hyprland's own (font size is monitor height / 76, text ends at 98% of the screen height). clicks go straight through it. it works next to caelestia, serpantinum, or any other shell, and does not patch them.
- **caelestia colors**: if caelestia is installed, the splash takes its color from your current scheme and follows it when the wallpaper changes. otherwise it uses hyprland's default `col.splash` (white at 33%).
- **cli**: `hyprquip` prints a splash for scripts, status bars, lock screens and greetings.
- **snippets**: ready-made configs for hyprlock, waybar, fastfetch, fish, bash/zsh and a caelestia toast.

## install

### aur

```sh
yay -S hyprquip-git
```

then turn on the desktop splash, either with systemd (if your session starts `graphical-session.target`, for example under uwsm):

```sh
systemctl --user enable --now hyprquip
```

or from your hyprland config:

```lua
-- hyprland.lua
hl.on("hyprland.start", function() hl.exec_cmd("qs -p /usr/share/hyprquip/quickshell") end)
```

```ini
# hyprland.conf
exec-once = qs -p /usr/share/hyprquip/quickshell
```

### install script

```sh
git clone https://github.com/iamanuclearwarhead/hyprquip
cd hyprquip
./install.sh
```

this installs to `~/.local` and asks whether to show the splash on your desktop. if you use caelestia it adds one autostart line to `~/.config/caelestia/hypr-user.lua`, otherwise to your `hyprland.lua` or `hyprland.conf`. with a systemd graphical session it enables the user service instead.

| option | what it does |
| --- | --- |
| `--system` | install to `/usr` (or `$PREFIX`) |
| `--service` / `--no-service` | enable the desktop splash without asking, or skip it |
| `--uninstall` | remove everything, including the autostart line |

the desktop splash needs [quickshell](https://quickshell.org). the cli only needs bash and coreutils.

## cli

```
hyprquip              random splash, holiday aware
hyprquip --session    the splash hyprland picked for this session (hyprctl splash)
hyprquip --daily      same splash all day
hyprquip --all        every splash
hyprquip --count      how many there are
hyprquip --list christmas
hyprquip --json       json for waybar
```

`HYPRQUIP_DATE=2026-12-25 hyprquip` pretends it is christmas. `HYPRQUIP_DATA` points at a different folder of splash lists.

## desktop splash config

optional, at `~/.config/hyprquip/config.json`. changes apply live.

```json
{
    "mode": "session",
    "refreshMinutes": 0,
    "color": "auto",
    "opacity": 0.333,
    "font": "Sans",
    "sizeDivisor": 76,
    "bottom": 0.02
}
```

| key | meaning |
| --- | --- |
| `mode` | `session` (matches hyprland), `daily` or `random` |
| `refreshMinutes` | pick a new splash every n minutes, `0` keeps one |
| `color` | `auto` (caelestia scheme or white) or any color like `#55ffffff` |
| `opacity` | opacity used by `auto` |
| `font` | font family, defaults to hyprland's `misc:splash_font_family` |
| `sizeDivisor` | font size is screen height divided by this |
| `bottom` | gap under the text as a fraction of screen height |

## snippets

all of these live in `share/hyprquip/snippets` after installing.

**hyprlock**

```ini
label {
    monitor =
    text = cmd[update:0] hyprquip --session
    color = rgba(255, 255, 255, 0.33)
    font_size = 14
    position = 0, 20
    halign = center
    valign = bottom
}
```

**waybar**

```jsonc
"custom/hyprquip": {
    "exec": "hyprquip --daily --json",
    "return-type": "json",
    "interval": 3600,
    "max-length": 80
}
```

**fastfetch**

```jsonc
{ "type": "command", "key": "splash", "text": "hyprquip --session" }
```

**fish**

```fish
function fish_greeting
    hyprquip
end
```

**bash / zsh**

```sh
command -v hyprquip >/dev/null && hyprquip
```

**caelestia toast**

```sh
caelestia shell toaster info hyprland "$(hyprquip --session)" auto_awesome
```

## updating the splash list

```sh
./tools/update-splashes.py          # from hyprland main
./tools/update-splashes.py v0.56.2  # from a tag
```

## credits

the splash texts are written by the hyprland project and its community, copyright (c) 2022-2026 vaxerski, under the bsd 3-clause license. see `data/LICENSE.hyprland`. hyprquip is not affiliated with or endorsed by hyprland.

hyprquip itself is bsd 3-clause too, see `LICENSE`.
