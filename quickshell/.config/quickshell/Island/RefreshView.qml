import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.Config
import qs.Services
import qs.Icons

/**
 * Panneau de rafraîchissement : relance à la demande les briques du bureau
 * qui se coincent (shell, réseau, son, portails, fond d'écran, Hyprland).
 *
 * Chaque tuile lance son script indépendamment : plusieurs peuvent tourner en
 * parallèle, et chacune affiche son propre retour (anneau → coche ou croix).
 * Le panneau NE se ferme PAS après un lancement — on veut voir le résultat.
 *
 * Navigation clavier : ←/→ ou Tab, 1–6 en direct, Entrée lance, Échap referme.
 * Ouvert par island:refresh ou l'IPC toggleRefresh.
 */
IslandView {
    id: root

    property int selIndex: 0
    // état par identifiant : "idle" | "running" | "ok" | "fail"
    // (objet réassigné en bloc — muter une clé ne notifierait pas les liaisons)
    property var states: ({})
    property string status: ""

    // `command` passe par `sh -c` sauf si `detached` : dans ce cas le script
    // survit à la mort du shell (indispensable pour se relancer soi-même).
    readonly property var entries: [
        {
            id: "quickshell",
            label: "Quickshell",
            tone: Theme.accent,
            detached: true,
            command: "qs kill; qs -d",
        },
        {
            id: "network",
            label: "Réseau",
            tone: Theme.secondary,
            // nmcli plutôt que `systemctl restart NetworkManager` : les actions
            // enable-disable-network sont autorisées sans mot de passe pour la
            // session active, donc aucune fenêtre polkit ne s'interpose.
            command: "nmcli networking off; sleep 1; nmcli networking on || exit 1; "
                   + "nmcli device wifi rescan >/dev/null 2>&1; exit 0",
        },
        {
            id: "audio",
            label: "Audio",
            tone: Theme.success,
            command: "systemctl --user restart pipewire pipewire-pulse wireplumber",
        },
        {
            id: "portals",
            label: "Portails",
            tone: Theme.powerRestart,
            // le backend d'abord, le frontal ensuite : l'inverse laisse
            // xdg-desktop-portal s'accrocher à un backend mort
            command: "systemctl --user restart xdg-desktop-portal-hyprland && sleep 0.5 && "
                   + "systemctl --user restart xdg-desktop-portal",
        },
        {
            id: "wallpaper",
            label: "Fond d'écran",
            tone: Theme.tileCircleOn,
            // bash, pas sh : le script utilise `disown`.
            // setsid --wait : hyprpaper doit vivre dans SA session, sinon il
            // hériterait du groupe de processus de quickshell et mourrait au
            // prochain `qs kill`. --wait conserve le code de retour du script.
            command: "setsid --wait bash ~/.config/hypr/wallpaper.sh >/dev/null 2>&1",
        },
        {
            id: "hyprland",
            label: "Hyprland",
            tone: Theme.powerLogout,
            command: "hyprctl reload && hyprctl setcursor Bibata-Modern-Classic 24",
        },
    ]

    readonly property int tileWidth: 86
    readonly property int circleSize: 44

    implicitWidth: row.implicitWidth + 2 * 18
    implicitHeight: 118

    onActiveChanged: {
        if (active) {
            selIndex = 0
            states = ({})
            status = ""
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: keys.forceActiveFocus()
    }

    function stateOf(id) {
        return root.states[id] || "idle"
    }

    function setState(id, s) {
        // réassignation complète : QML ne détecte pas la mutation d'une clé
        const next = {}
        for (const k in root.states)
            next[k] = root.states[k]
        next[id] = s
        root.states = next
    }

    function run(idx) {
        const entry = root.entries[idx]
        if (root.stateOf(entry.id) === "running")
            return

        if (entry.detached) {
            root.status = entry.label + " relancé…"
            Quickshell.execDetached(["sh", "-c", entry.command])
            return
        }

        root.setState(entry.id, "running")
        root.status = entry.label + "…"
        procs.objectAt(idx).running = true
    }

    function finish(idx, ok) {
        const entry = root.entries[idx]
        root.setState(entry.id, ok ? "ok" : "fail")
        root.status = ok ? entry.label + " relancé" : "Échec : " + entry.label
        resetTimer.restart()
    }

    // retour au neutre après un instant : les coches ne doivent pas rester
    // affichées si le panneau est rouvert plus tard
    Timer {
        id: resetTimer
        interval: 2600
        onTriggered: {
            const next = {}
            for (const k in root.states)
                if (root.states[k] === "running")
                    next[k] = "running"
            root.states = next
            if (Object.keys(next).length === 0)
                root.status = ""
        }
    }

    Instantiator {
        id: procs
        model: root.entries.length

        delegate: Process {
            required property int index
            command: ["sh", "-c", root.entries[index].command]
            onExited: (exitCode, exitStatus) => root.finish(index, exitCode === 0)
        }
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
        Keys.onReturnPressed: root.run(root.selIndex)
        Keys.onEnterPressed: root.run(root.selIndex)
        Keys.onEscapePressed: IslandState.closePanel()
        // 1–6 : lancement direct sans passer par la sélection
        Keys.onPressed: event => {
            const n = event.key - Qt.Key_1
            if (n >= 0 && n < root.entries.length) {
                root.selIndex = n
                root.run(n)
                event.accepted = true
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 8

        Row {
            id: row
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            Repeater {
                model: root.entries.length

                delegate: Item {
                    required property int index
                    readonly property var entry: root.entries[index]
                    readonly property string st: root.stateOf(entry.id)
                    readonly property bool selected: index === root.selIndex
                    readonly property color tone:
                        st === "ok" ? Theme.success
                      : st === "fail" ? Theme.critical
                      : entry.tone

                    width: root.tileWidth
                    height: root.circleSize + 6 + 14

                    Rectangle {
                        id: circle
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.circleSize
                        height: root.circleSize
                        radius: width / 2
                        color: selected || tileMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                        border.color: selected || st !== "idle" ? tone : "transparent"
                        border.width: 1.5
                        Behavior on color { ColorAnimation { duration: 110 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        // icône propre à l'action, remplacée par le verdict
                        Item {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            opacity: st === "ok" || st === "fail" ? 0 : 1
                            Behavior on opacity { NumberAnimation { duration: Theme.fadeDuration } }

                            RestartIcon { anchors.centerIn: parent; visible: index === 0; size: 21; color: tone }
                            GlobeIcon   { anchors.centerIn: parent; visible: index === 1; size: 21; color: tone }
                            SpeakerIcon { anchors.centerIn: parent; visible: index === 2; size: 21; color: tone; volume: 1 }
                            ScreenIcon  { anchors.centerIn: parent; visible: index === 3; size: 21; color: tone }
                            ImageIcon   { anchors.centerIn: parent; visible: index === 4; size: 21; color: tone }
                            TilingIcon  { anchors.centerIn: parent; visible: index === 5; size: 21; color: tone }
                        }

                        CheckIcon {
                            anchors.centerIn: parent
                            size: 21
                            color: Theme.success
                            opacity: st === "ok" ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.fadeDuration } }
                        }

                        CloseIcon {
                            anchors.centerIn: parent
                            size: 19
                            color: Theme.critical
                            opacity: st === "fail" ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.fadeDuration } }
                        }

                        // anneau tournant pendant l'exécution
                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            visible: st === "running"
                            transformOrigin: Item.Center

                            ShapePath {
                                strokeWidth: 2
                                strokeColor: Theme.accent
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                PathAngleArc {
                                    centerX: root.circleSize / 2
                                    centerY: root.circleSize / 2
                                    radiusX: root.circleSize / 2 - 1
                                    radiusY: root.circleSize / 2 - 1
                                    startAngle: 0; sweepAngle: 95
                                }
                            }

                            RotationAnimator on rotation {
                                from: 0; to: 360
                                duration: 900
                                loops: Animation.Infinite
                                running: st === "running"
                            }
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.run(index)
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        text: entry.label
                        color: selected ? Theme.fg : Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall - 1
                        font.weight: Theme.fontWeight
                        Behavior on color { ColorAnimation { duration: 110 } }
                    }
                }
            }
        }

        // ligne de retour — hauteur réservée pour que la pilule ne sursaute pas
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            height: 15
            text: root.status
            color: root.status.startsWith("Échec") ? Theme.critical : Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall - 1
            font.weight: Theme.fontWeight
            opacity: root.status === "" ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.fadeDuration } }
        }
    }
}
