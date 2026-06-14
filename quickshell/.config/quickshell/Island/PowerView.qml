import QtQuick
import Quickshell
import qs.Config
import qs.Services
import qs.Icons

/**
 * Menu d'alimentation : éteindre / redémarrer / se déconnecter.
 * Compact (même hauteur que la vue étendue → centré dans la bande),
 * icônes seules dans des ronds colorés.
 * Navigation clavier : ←/→ ou Tab (boucle, Shift+Tab en arrière),
 * Entrée active, Échap referme. Ouvert par island:power ou l'IPC togglePower.
 */
IslandView {
    id: root

    property int selIndex: 0

    // `tone` = couleur d'icône + liseré de sélection, réglable dans Theme.qml
    readonly property var entries: [
        {
            label: "Éteindre",
            tone: Theme.powerOff,
            command: ["systemctl", "poweroff"],
        },
        {
            label: "Redémarrer",
            tone: Theme.powerRestart,
            command: ["systemctl", "reboot"],
        },
        {
            label: "Déconnexion",
            tone: Theme.powerLogout,
            // syntaxe classique, puis repli Lua (Hyprland ≥ 0.55)
            command: ["sh", "-c", "hyprctl dispatch exit || hyprctl dispatch 'hl.dsp.exit()'"],
        },
    ]

    implicitWidth: row.implicitWidth + 2 * 18
    implicitHeight: Settings.expandedHeight

    onActiveChanged: {
        if (active) {
            selIndex = 0
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: keys.forceActiveFocus()
    }

    function activate(idx) {
        Quickshell.execDetached(root.entries[idx].command)
        IslandState.closePanel()
    }

    function cycle(step) {
        const n = root.entries.length
        root.selIndex = (root.selIndex + step + n) % n
    }

    Item {
        id: keys
        focus: root.active
        Keys.onLeftPressed: root.cycle(-1)
        Keys.onRightPressed: root.cycle(1)
        Keys.onTabPressed: root.cycle(1)
        Keys.onBacktabPressed: root.cycle(-1)   // Shift+Tab
        Keys.onReturnPressed: root.activate(root.selIndex)
        Keys.onEnterPressed: root.activate(root.selIndex)
        Keys.onEscapePressed: IslandState.closePanel()
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: root.entries.length

            delegate: Rectangle {
                required property int index
                readonly property var entry: root.entries[index]
                readonly property bool selected: index === root.selIndex
                readonly property color tone: entry.tone

                width: 40
                height: 40
                radius: 20
                color: selected || tileMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                border.color: selected ? tone : "transparent"
                border.width: 1.5
                Behavior on color { ColorAnimation { duration: 110 } }

                PowerIcon {
                    anchors.centerIn: parent
                    visible: index === 0
                    size: 21
                    color: tone
                }
                RestartIcon {
                    anchors.centerIn: parent
                    visible: index === 1
                    size: 21
                    color: tone
                }
                LogoutIcon {
                    anchors.centerIn: parent
                    visible: index === 2
                    size: 21
                    color: tone
                }

                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activate(index)
                }
            }
        }
    }
}
