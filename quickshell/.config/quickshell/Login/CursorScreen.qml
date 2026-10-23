import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Nom de l'écran sous le curseur, lu auprès d'Hyprland (`hyprctl cursorpos`).
 *
 * On ne peut pas se fier au survol des fenêtres : quand une surface
 * layer-shell prend le clavier en exclusivité (greeter), Hyprland y garde
 * aussi la souris, et les autres écrans ne la voient jamais arriver.
 */
Scope {
    id: root

    property bool enabled: true
    property string screenName: ""

    // ne change d'écran que si la souris a vraiment bougé
    property real lastX: NaN
    property real lastY: NaN

    Timer {
        interval: 150
        repeat: true
        running: root.enabled
        triggeredOnStart: true
        onTriggered: if (!poll.running) poll.running = true
    }

    Process {
        id: poll
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p
                try { p = JSON.parse(text) } catch (e) { return }
                if (p.x === root.lastX && p.y === root.lastY) return
                root.lastX = p.x
                root.lastY = p.y
                const s = Quickshell.screens.find(s =>
                    p.x >= s.x && p.x < s.x + s.width && p.y >= s.y && p.y < s.y + s.height)
                if (s && s.name !== root.screenName) root.screenName = s.name
            }
        }
    }
}
