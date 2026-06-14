import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Config
import qs.Services
import qs.Icons

/**
 * Lanceur : barre de recherche à focus verrouillé, navigation 100 % clavier
 * (le curseur souris est masqué au-dessus de l'îlot).
 *
 *   texte    → recherche d'applications
 *   =expr    → calculatrice temps réel (Entrée copie le résultat)
 *   /motif   → recherche de fichiers dans ~ (Entrée ouvre avec xdg-open)
 *
 * Les résultats apparaissent en fondu, les obsolètes disparaissent, les
 * restants glissent vers leur nouvelle position (transitions ListView).
 */
IslandView {
    id: root

    readonly property string mode: input.text.startsWith(Settings.calcPrefix) ? "calc"
                                 : input.text.startsWith(Settings.filePrefix) ? "files"
                                 : "apps"
    readonly property string term: mode === "apps" ? input.text : input.text.slice(1)

    property int selIndex: 0
    readonly property int rowH: 46

    readonly property var results: {
        if (!active)
            return []
        if (mode === "calc") {
            return [{
                kind: "calc",
                expr: term.trim(),
                value: calc(term),
            }]
        }
        if (mode === "files")
            return FileSearch.results.slice(0, Settings.launcherMaxResults)
        return AppSearch.query(input.text, Settings.launcherMaxResults)
    }

    implicitWidth: Settings.maxWidth
    implicitHeight: 54 + (results.length > 0 ? list.height + 12 : 4)

    onTermChanged: {
        selIndex = 0
        if (mode === "files")
            FileSearch.search(term)
    }
    // "fire" → "/fire" garde le même term mais change de mode : réinitialiser
    onModeChanged: {
        selIndex = 0
        if (mode === "files")
            FileSearch.search(term)
    }
    onActiveChanged: {
        if (active) {
            input.text = ""
            selIndex = 0
            focusTimer.restart()
        }
    }

    // le focus clavier exclusif (layer-shell) arrive avec une latence d'une frame
    Timer {
        id: focusTimer
        interval: 60
        onTriggered: input.forceActiveFocus()
    }

    // navigation clavier uniquement : la souris est masquée sur l'îlot
    HoverHandler {
        cursorShape: Qt.BlankCursor
    }

    function calc(raw) {
        let s = raw.trim()
        if (s === "")
            return ""
        const words = s.match(/[a-zA-Z]+/g) || []
        const allowed = ["sqrt", "sin", "cos", "tan", "abs", "log", "exp",
                         "floor", "ceil", "round", "min", "max", "pow", "pi", "PI"]
        for (const w of words) {
            if (!allowed.includes(w))
                return "?"
        }
        if (!/^[0-9a-zA-Z+\-*/().,%^ ]*$/.test(s))
            return "?"
        s = s.replace(/,/g, ".")
             .replace(/\^/g, "**")
             .replace(/\b(sqrt|sin|cos|tan|abs|log|exp|floor|ceil|round|min|max|pow)\b/g, "Math.$1")
             .replace(/\bpi\b/gi, "Math.PI")
        try {
            const v = Function('"use strict"; return (' + s + ')')()
            if (typeof v === "number" && isFinite(v))
                return String(parseFloat(v.toPrecision(12)))
        } catch (e) {}
        return "?"
    }

    function activate() {
        const r = results[selIndex]
        if (!r)
            return
        if (mode === "apps") {
            r.execute()
            IslandState.closeLauncher()
        } else if (mode === "calc") {
            if (r.value !== "" && r.value !== "?") {
                Quickshell.clipboardText = r.value
                IslandState.closeLauncher()
            }
        } else {
            FileSearch.open(r.path)
            IslandState.closeLauncher()
        }
    }

    Column {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 36
        spacing: 4

        // ── barre de saisie ─────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 52

            Item {
                id: modeIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22

                SearchIcon { anchors.centerIn: parent; size: 19; visible: root.mode === "apps"; color: Theme.accent }
                CalcIcon { anchors.centerIn: parent; size: 19; visible: root.mode === "calc"; color: Theme.accent }
                FolderIcon { anchors.centerIn: parent; size: 19; visible: root.mode === "files"; color: Theme.accent }
            }

            TextInput {
                id: input
                anchors.left: modeIcon.right
                anchors.leftMargin: 12
                anchors.right: hint.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Theme.fontWeight
                clip: true

                Keys.onUpPressed: root.selIndex = Math.max(0, root.selIndex - 1)
                Keys.onDownPressed: root.selIndex = Math.max(0, Math.min(root.results.length - 1, root.selIndex + 1))
                Keys.onReturnPressed: root.activate()
                Keys.onEnterPressed: root.activate()
                Keys.onEscapePressed: IslandState.closeLauncher()

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text === ""
                    text: "Rechercher…"
                    color: Theme.fgDim
                    opacity: 0.7
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Theme.fontWeight
                }
            }

            Text {
                id: hint
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.mode === "calc" ? "Entrée : copier"
                    : root.mode === "files" ? "Entrée : ouvrir"
                    : ""
                color: Theme.fgDim
                opacity: 0.7
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall - 1
                font.weight: Theme.fontWeight
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.islandBorder
            visible: root.results.length > 0
        }

        // ── résultats ───────────────────────────────────────────────────────
        ListView {
            id: list
            width: parent.width
            height: root.results.length * root.rowH
            interactive: false
            clip: true
            currentIndex: root.selIndex

            model: ScriptModel {
                values: root.results
            }

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 170; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 170; easing.type: Easing.OutCubic }
            }
            displaced: Transition {
                NumberAnimation { properties: "y"; duration: 190; easing.type: Easing.OutCubic }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: 110 }
            }

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index

                readonly property bool isApp: root.mode === "apps"
                readonly property bool isCalc: root.mode === "calc"
                readonly property string appIcon:
                    isApp && modelData.icon !== "" ? Quickshell.iconPath(modelData.icon, true) : ""

                width: list.width
                height: root.rowH
                radius: 14
                color: index === root.selIndex ? Theme.surfaceHover : "transparent"
                Behavior on color { ColorAnimation { duration: 90 } }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    // pictogramme
                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 26
                            visible: row.appIcon !== ""
                            source: row.appIcon
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            visible: row.isApp && row.appIcon === ""
                            color: Qt.alpha(Theme.accent, 0.85)
                            Text {
                                anchors.centerIn: parent
                                text: row.isApp && row.modelData.name !== "" ? row.modelData.name[0].toUpperCase() : ""
                                color: Theme.islandBg
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.weight: Theme.fontWeightStrong
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: row.isCalc
                            text: "="
                            color: Theme.accent
                            font.family: Theme.monoFamily
                            font.pixelSize: 19
                            font.weight: Theme.fontWeightStrong
                        }

                        FileIcon {
                            anchors.centerIn: parent
                            visible: !row.isApp && !row.isCalc
                            size: 18
                            color: Theme.fgDim
                        }
                    }

                    // libellés
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            width: 420
                            elide: Text.ElideRight
                            text: row.isApp ? row.modelData.name
                                : row.isCalc ? (row.modelData.expr === "" ? "Tapez une expression…" : row.modelData.expr)
                                : row.modelData.name
                            color: Theme.fg
                            font.family: row.isCalc ? Theme.monoFamily : Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                            font.weight: row.isCalc ? Theme.fontWeight : Theme.fontWeightStrong
                        }

                        Text {
                            width: 420
                            visible: text !== ""
                            elide: Text.ElideRight
                            text: row.isApp
                                  ? (row.modelData.genericName !== "" ? row.modelData.genericName : row.modelData.comment)
                                  : row.isCalc ? "" : row.modelData.dir
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.fontWeight
                        }
                    }
                }

                // résultat de calcul en temps réel, à droite
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    visible: row.isCalc && row.modelData.value !== ""
                    text: "= " + row.modelData.value
                    color: row.modelData.value === "?" ? Theme.critical : Theme.accent
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Theme.fontWeightStrong
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.selIndex = row.index
                        root.activate()
                    }
                }
            }
        }
    }
}
