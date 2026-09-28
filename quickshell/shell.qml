import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || home + "/.local/state"

    property var cfg: ({})
    readonly property string mode: cfg.mode ?? "session"
    readonly property string font: cfg.font ?? hyprFont
    readonly property real sizeDivisor: cfg.sizeDivisor ?? 76
    readonly property real bottom: cfg.bottom ?? 0.02
    readonly property int refreshMinutes: cfg.refreshMinutes ?? 0
    readonly property string colorSetting: cfg.color ?? "auto"
    readonly property real opacityAuto: cfg.opacity ?? 0.85
    readonly property bool shadow: cfg.shadow ?? true
    readonly property string toneSetting: cfg.tone ?? "auto"

    property string hyprFont: "Sans"
    property string splash: ""
    property string day: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property var scheme: null
    property string caelestiaWall: ""
    property real wallBrightness: -1

    readonly property string wallpaper: cfg.wallpaper ?? caelestiaWall
    readonly property bool darkText: toneSetting === "dark" || (toneSetting === "auto" && wallBrightness > 0.5)

    readonly property color lightColor: scheme && scheme.colours && scheme.colours.onSurface ? "#" + scheme.colours.onSurface : "#ffffff"
    readonly property color darkColor: scheme && scheme.colours && scheme.colours.surface ? "#" + scheme.colours.surface : "#000000"

    readonly property color textColor: colorSetting !== "auto" ? colorSetting : Qt.alpha(darkText ? darkColor : lightColor, opacityAuto)
    readonly property color shadowColor: cfg.shadowColor ?? (darkText ? lightColor : darkColor)

    onWallpaperChanged: {
        probe.running = false;
        if (!wallpaper)
            return;
        probe.command = ["sh", "-c", "[ -f \"$1\" ] && magick \"$1[0]\" -resize '1920x1080^' -gravity center -extent 1920x1080 -gravity south -crop 50%x6%+0+0 -colorspace gray -format '%[fx:mean]' info: 2>/dev/null", "sh", wallpaper];
        probe.running = true;
    }

    FileView {
        path: root.stateHome + "/caelestia/wallpaper/path.txt"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.caelestiaWall = text().trim()
    }

    Process {
        id: probe
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseFloat(text);
                root.wallBrightness = isNaN(v) ? -1 : v;
            }
        }
    }

    FileView {
        path: root.configHome + "/hyprquip/config.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.cfg = JSON.parse(text());
            } catch (e) {
                root.cfg = {};
            }
            fetch.running = true;
        }
        onLoadFailed: {
            root.cfg = {};
            fetch.running = true;
        }
    }

    FileView {
        path: root.stateHome + "/caelestia/scheme.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.scheme = JSON.parse(text());
            } catch (e) {}
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "hyprctl getoption misc:splash_font_family -j 2>/dev/null; hyprctl getoption misc:font_family -j 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fonts = text.split(/\n(?=\{)/).map(s => {
                    try {
                        return JSON.parse(s).str;
                    } catch (e) {
                        return "";
                    }
                }).filter(s => s && s !== "[[EMPTY]]");
                if (fonts.length)
                    root.hyprFont = fonts[0];
            }
        }
    }

    Process {
        id: fetch
        command: [Quickshell.shellDir + "/../hyprquip", "--" + root.mode]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim();
                if (s)
                    root.splash = s;
            }
        }
    }

    Timer {
        running: root.refreshMinutes > 0
        repeat: true
        interval: root.refreshMinutes * 60000
        onTriggered: fetch.running = true
    }

    Timer {
        running: root.mode !== "session"
        repeat: true
        interval: 60000
        onTriggered: {
            const today = Qt.formatDate(new Date(), "yyyy-MM-dd");
            if (today !== root.day) {
                root.day = today;
                fetch.running = true;
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "hyprquip"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors.bottom: true
            margins.bottom: Math.round(modelData.height * root.bottom) - 14
            implicitWidth: label.implicitWidth + 32
            implicitHeight: label.implicitHeight + 28
            color: "transparent"
            mask: Region {}
            visible: root.splash !== ""

            Text {
                id: label
                anchors.centerIn: parent
                visible: !root.shadow
                text: root.splash
                color: root.textColor
                font.family: root.font
                font.pixelSize: Math.max(1, Math.round(modelData.height / root.sizeDivisor))
                textFormat: Text.PlainText
                renderType: Text.NativeRendering

                Behavior on color {
                    ColorAnimation {
                        duration: 400
                    }
                }
            }

            MultiEffect {
                anchors.fill: label
                source: label
                visible: root.shadow
                shadowEnabled: true
                shadowColor: root.shadowColor
                shadowOpacity: 0.8
                shadowBlur: 1.0
                blurMax: 12
                paddingRect: Qt.rect(14, 14, 28, 28)
            }
        }
    }
}
