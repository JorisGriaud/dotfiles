import QtQuick
import QtQuick.Effects
import qs.Config
import qs.Icons
import qs.Services

/**
 * Le visuel commun au greeter et à l'écran de verrouillage
 * (mélange des maquettes « Island » et « Horloge centrale ») :
 * fond d'écran assombri, pilule d'îlot en haut, grande horloge fine,
 * puis la pilule de connexion (avatar · nom · champ · bouton).
 *
 * `ctl` = GreeterController ou LockController. Seul l'écran `active`
 * (celui où est la souris) affiche le formulaire ; les autres gardent
 * le fond et l'horloge.
 */
Item {
    id: root

    required property var ctl
    required property string screenName
    readonly property bool active: ctl.activeScreen === "" || ctl.activeScreen === screenName
    readonly property bool lockMode: ctl.mode === "lock"
    readonly property bool multiUser: ctl.users.length > 1

    // échelle : 1 pour un écran de 1440 px de haut (logique)
    readonly property real u: Math.max(0.6, height / 1440)

    // la souris qui entre sur cet écran y amène le formulaire
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: root.ctl.activeScreen = root.screenName
    }

    onActiveChanged: {
        field.text = ""
        if (active) field.forceActiveFocus()
    }
    Component.onCompleted: if (active) field.forceActiveFocus()

    // ── fond ────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#0b0e14"
    }

    FallbackImage {
        anchors.fill: parent
        sources: root.ctl.loginData.wallpaperSources(root.screenName)
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.04, 0.05, 0.08, 0.30) }
            GradientStop { position: 0.6; color: Qt.rgba(0.04, 0.05, 0.08, 0.55) }
            GradientStop { position: 1.0; color: Qt.rgba(0.04, 0.05, 0.08, 0.80) }
        }
    }

    // ── pilule d'îlot en haut ───────────────────────────────────────────────
    Pill {
        id: topIsland
        anchors.top: parent.top
        anchors.topMargin: Settings.topMargin
        anchors.horizontalCenter: parent.horizontalCenter
        height: Settings.restHeight
        width: topRow.implicitWidth + Settings.contentPadding * 2

        Row {
            id: topRow
            anchors.centerIn: parent
            spacing: 10

            LockIcon {
                anchors.verticalCenter: parent.verticalCenter
                size: 15
                color: root.lockMode ? Theme.accent : Theme.icon
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.lockMode ? "Session verrouillée" : (root.ctl.loginData.hostname || "Connexion")
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                font.weight: Theme.fontWeightStrong
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.ctl.mode === "demo"
                width: 1; height: 14
                color: Theme.islandBorder
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.ctl.mode === "demo"
                text: "Aperçu (Échap pour quitter)"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                font.weight: Theme.fontWeight
            }
        }
    }

    // ── horloge centrale ────────────────────────────────────────────────────
    Column {
        id: clockCol
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * (root.active ? 0.20 : 0.30)
        spacing: 4 * root.u

        Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.time
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 230 * root.u
            font.weight: 200
            font.letterSpacing: -6 * root.u
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.longDate
            color: Qt.rgba(1, 1, 1, 0.78)
            font.family: Theme.fontFamily
            font.pixelSize: 30 * root.u
            font.weight: 300
        }
    }

    // ── formulaire : avatar cerclé, nom, champ translucide ──────────────────
    Column {
        id: form
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.52
        spacing: 14
        opacity: root.active ? 1 : 0
        visible: opacity > 0
        enabled: root.active

        Behavior on opacity { NumberAnimation { duration: 260 } }

        // liste des comptes (si plusieurs) : petites pastilles cliquables
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            visible: root.multiUser
            bottomPadding: 6

            Repeater {
                model: root.ctl.users

                Avatar {
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === root.ctl.userIndex
                    size: 34
                    label: modelData.realName
                    sources: root.ctl.loginData.avatarSources(modelData.name)
                    opacity: selected ? 1 : 0.45
                    border.width: selected ? 2 : 0
                    border.color: Qt.rgba(1, 1, 1, 0.8)

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.ctl.selectUser(index); field.forceActiveFocus() }
                    }
                }
            }
        }

        // avatar avec anneau clair
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 112
            height: 112
            radius: width / 2
            color: "transparent"
            border.width: 3
            border.color: Qt.rgba(1, 1, 1, 0.75)

            Avatar {
                anchors.centerIn: parent
                size: 104
                label: root.ctl.user?.realName ?? "?"
                sources: root.ctl.user ? root.ctl.loginData.avatarSources(root.ctl.user.name) : []
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.ctl.user?.name ?? ""
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 22
            font.weight: Theme.fontWeightStrong
        }

        // champ du mot de passe (Entrée pour valider, pas de bouton)
        Rectangle {
            id: fieldBg
            anchors.horizontalCenter: parent.horizontalCenter
            width: 340
            height: 50
            radius: height / 2
            color: Qt.rgba(0.11, 0.12, 0.15, field.activeFocus ? 0.78 : 0.68)
            border.width: 1
            border.color: root.ctl.errorText !== "" ? Theme.critical : Qt.rgba(1, 1, 1, 0.24)

            Behavior on border.color { ColorAnimation { duration: Theme.fadeDuration } }

            transform: Translate { id: shakeT }

            SequentialAnimation {
                id: shake
                NumberAnimation { target: shakeT; property: "x"; to: -14; duration: 50 }
                NumberAnimation { target: shakeT; property: "x"; to: 12; duration: 70 }
                NumberAnimation { target: shakeT; property: "x"; to: -8; duration: 70 }
                NumberAnimation { target: shakeT; property: "x"; to: 5; duration: 60 }
                NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 50 }
            }
            Connections {
                target: root.ctl
                function onFailCountChanged() {
                    shake.restart()
                    field.text = ""
                    field.forceActiveFocus()
                }
            }

            TextInput {
                id: field
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                passwordMaskDelay: 0
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.letterSpacing: 6
                selectionColor: Theme.accent
                clip: true
                readOnly: root.ctl.busy

                onTextChanged: if (text !== "") root.ctl.errorText = ""
                onAccepted: if (text !== "") root.ctl.submit(text)

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Tab) {
                        root.ctl.nextSession()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        if (text === "") root.ctl.quitDemo()
                        text = ""
                        event.accepted = true
                    } else if (text === "" && event.key === Qt.Key_Left) {
                        root.ctl.selectUser(root.ctl.userIndex - 1)
                        event.accepted = true
                    } else if (text === "" && event.key === Qt.Key_Right) {
                        root.ctl.selectUser(root.ctl.userIndex + 1)
                        event.accepted = true
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: field.text === ""
                text: root.ctl.busy ? "Vérification…" : "Mot de passe"
                color: Qt.rgba(1, 1, 1, 0.5)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                font.weight: Theme.fontWeight
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: field.forceActiveFocus()
            }
        }

        // erreur / réussite seulement (vide au repos, mais garde sa hauteur
        // pour que rien ne saute quand un message apparaît)
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.ctl.statusText !== "" ? root.ctl.statusText : root.ctl.errorText
            color: root.ctl.statusText !== "" ? Theme.success : Theme.critical
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall + 1
            font.weight: Theme.fontWeight
        }
    }

    // ── rangée du bas : session · clavier · alimentation ────────────────────
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 34
        spacing: 36
        opacity: root.active ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 260 } }

        // session (clic ou Tab = suivante)
        Item {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: sessRow.implicitWidth
            implicitHeight: sessRow.implicitHeight
            visible: !root.lockMode && root.ctl.sessions.length > 0
            opacity: sessMouse.containsMouse ? 1 : 0.7

            Row {
                id: sessRow
                spacing: 8
                ScreenIcon { anchors.verticalCenter: parent.verticalCenter; size: 18; color: Theme.fg }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.ctl.session?.name ?? ""
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal + 1
                    font.weight: Theme.fontWeight
                }
            }

            MouseArea {
                id: sessMouse
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { root.ctl.nextSession(); field.forceActiveFocus() }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "FR"
            color: Theme.fg
            opacity: 0.7
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal + 1
            font.weight: Theme.fontWeight
        }

        PowerIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.lockMode
            size: 20
            color: powerMouse.containsMouse ? Theme.powerOff : Theme.fg
            opacity: powerMouse.containsMouse ? 1 : 0.7

            MouseArea {
                id: powerMouse
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.ctl.power("poweroff")
            }
        }
    }
}
