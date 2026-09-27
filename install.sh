#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

SYSTEM=0
UNINSTALL=0
SERVICE=ask
DESTDIR=${DESTDIR:-}

usage() {
    cat <<EOF
usage: ./install.sh [options]

  --system        install to /usr (or \$PREFIX) instead of ~/.local
  --uninstall     remove hyprquip
  --service       enable the desktop splash service without asking
  --no-service    do not enable the desktop splash service
  -h, --help      show this help

env: PREFIX, DESTDIR
EOF
}

while (( $# )); do
    case $1 in
        --system) SYSTEM=1 ;;
        --uninstall) UNINSTALL=1 ;;
        --service) SERVICE=yes ;;
        --no-service) SERVICE=no ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown option '$1'" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if (( SYSTEM )); then
    PREFIX=${PREFIX:-/usr}
    UNITDIR=$PREFIX/lib/systemd/user
else
    PREFIX=${PREFIX:-$HOME/.local}
    UNITDIR=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user
fi
SHARE=$PREFIX/share/hyprquip
BIN=$PREFIX/bin
QS=/usr/bin/qs
(( SYSTEM )) || QS=$(command -v qs || echo /usr/bin/qs)

CFG=${XDG_CONFIG_HOME:-$HOME/.config}

autostart_file() {
    for f in "$CFG/caelestia/hypr-user.lua" "$CFG/hypr/hyprland.lua" "$CFG/hypr/hyprland.conf"; do
        [[ -f $f ]] && { echo "$f"; return; }
    done
}

autostart_line() {
    if [[ $1 == *.lua ]]; then
        echo "hl.on(\"hyprland.start\", function() hl.exec_cmd(\"qs -p $SHARE/quickshell\") end)"
    else
        echo "exec-once = qs -p $SHARE/quickshell"
    fi
}

remove_autostart() {
    local f
    for f in "$CFG/caelestia/hypr-user.lua" "$CFG/hypr/hyprland.lua" "$CFG/hypr/hyprland.conf"; do
        [[ -f $f ]] && grep -q "hyprquip/quickshell" "$f" && sed -i "\|hyprquip/quickshell|d" "$f" && echo "removed autostart from $f"
    done
    return 0
}

have_session() {
    [[ -z $DESTDIR ]] && systemctl --user is-active --quiet graphical-session.target 2>/dev/null
}

if (( UNINSTALL )); then
    if (( ! SYSTEM )) && [[ -z $DESTDIR ]]; then
        systemctl --user disable --now hyprquip.service 2>/dev/null || true
        pkill -f "qs -p $SHARE/quickshell" 2>/dev/null || true
        remove_autostart
    fi
    rm -rf "$DESTDIR$SHARE"
    rm -f "$DESTDIR$BIN/hyprquip" "$DESTDIR$UNITDIR/hyprquip.service"
    [[ -z $DESTDIR ]] && systemctl --user daemon-reload 2>/dev/null || true
    echo "hyprquip removed"
    exit 0
fi

install -Dm755 hyprquip "$DESTDIR$SHARE/hyprquip"
install -Dm644 -t "$DESTDIR$SHARE/data" data/*.txt data/LICENSE.hyprland
install -Dm644 -t "$DESTDIR$SHARE/quickshell" quickshell/shell.qml
install -Dm644 -t "$DESTDIR$SHARE/snippets" snippets/*
install -Dm644 config.example.json "$DESTDIR$SHARE/config.example.json"
install -d "$DESTDIR$BIN"
ln -sf "$SHARE/hyprquip" "$DESTDIR$BIN/hyprquip"

install -d "$DESTDIR$UNITDIR"
sed -e "s|/usr/bin/qs|$QS|" -e "s|/usr/share/hyprquip|$SHARE|" systemd/hyprquip.service > "$DESTDIR$UNITDIR/hyprquip.service"
chmod 644 "$DESTDIR$UNITDIR/hyprquip.service"

echo "installed hyprquip to $PREFIX"
[[ -n $DESTDIR ]] && exit 0

command -v qs >/dev/null || echo "note: quickshell (qs) is not installed, the desktop splash needs it. the cli works without it."
case ":$PATH:" in *":$BIN:"*) ;; *) echo "note: $BIN is not in your PATH" ;; esac

if [[ $SERVICE == ask ]]; then
    if [[ -t 0 ]] && { have_session || [[ -n $(autostart_file) ]]; }; then
        read -rp "show the splash on your desktop now and on every login? [Y/n] " a
        [[ ${a,,} == n* ]] && SERVICE=no || SERVICE=yes
    else
        SERVICE=no
    fi
fi

if [[ $SERVICE == yes ]]; then
    if have_session; then
        systemctl --user daemon-reload
        systemctl --user enable --now hyprquip.service
        echo "desktop splash enabled (systemctl --user disable --now hyprquip to turn it off)"
    elif f=$(autostart_file) && [[ -n $f ]]; then
        if ! grep -q "hyprquip/quickshell" "$f"; then
            [[ -z $(tail -c1 "$f") ]] || echo >> "$f"
            autostart_line "$f" >> "$f"
        fi
        echo "added autostart to $f"
        if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && ! pgrep -f "qs -p $SHARE/quickshell" >/dev/null; then
            setsid -f qs -p "$SHARE/quickshell" >/dev/null 2>&1
        fi
        echo "desktop splash enabled"
    else
        echo "could not find your hyprland config, add one of these yourself:"
        echo "  hyprland.lua:  $(autostart_line x.lua)"
        echo "  hyprland.conf: $(autostart_line x.conf)"
    fi
fi

echo "snippets for hyprlock, waybar, fastfetch and your shell are in $SHARE/snippets"
