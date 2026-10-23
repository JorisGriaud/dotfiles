import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.Config
import qs.Services
import qs.Widgets
import qs.Icons

/**
 * Notification dans l'îlot.
 *
 *  - ligne d'en-tête : application et heure (« Discord, à l'instant »),
 *    ou « Discord, 4 notifications » pour un groupe
 *  - corps en texte riche nettoyé, déplié au survol
 *  - groupe : les deux précédentes en aperçu sous la plus récente
 *  - boutons d'action, champ de réponse rapide si l'application le permet
 *  - vignette si la notification porte une image ET une icône d'application
 *  - à droite : « +N » (file d'attente ; clic molette = tout passer),
 *    croix pour les critiques (elles ne partent pas seules)
 *  - en bas : barre du temps restant, figée (orange) pendant la pause
 *
 * Clic n'importe où ailleurs = ouvrir, clic molette = fermer : géré par la
 * MouseArea de fond d'Island.qml. Le survol met le chronomètre en pause.
 */
IslandView {
    id: root

    readonly property var n: Notifs.current
    readonly property var grp: Notifs.group
    readonly property bool synthetic: n !== null && n.synthetic === true
    readonly property bool critical: Notifs.isCritical(n)
    readonly property color tone: critical ? Theme.critical : Theme.accent
    readonly property bool hovered: Notifs.hoverPaused
    readonly property var actions: Notifs.visibleActions(n)
    readonly property bool canReply: n !== null && !synthetic && n.hasInlineReply === true
    readonly property int queued: Notifs.queue.length

    // icône d'application, et image de contenu (vignette) quand les deux existent
    readonly property string appIconSource: {
        if (!n || synthetic || n.appIcon === "")
            return ""
        if (n.appIcon.startsWith("/") || n.appIcon.startsWith("file://"))
            return n.appIcon
        return Quickshell.iconPath(n.appIcon, true)
    }
    readonly property string imageSource: n && !synthetic ? n.image : ""
    readonly property bool showThumb: imageSource !== "" && appIconSource !== ""
    readonly property string iconSource: appIconSource !== "" ? appIconSource : imageSource

    readonly property int pad: 14
    readonly property int textX: pad + 36 + 12
    readonly property int textWidth: implicitWidth - textX - pad - side.width - (side.width > 0 ? 10 : 0)

    implicitWidth: 440
    implicitHeight: Math.max(60, main.implicitHeight + 24)

    // ── barre de temps restant ──────────────────────────────────────────────
    property real progress: 1

    NumberAnimation {
        id: drain
        target: root
        property: "progress"
        to: 0
    }

    Connections {
        target: Notifs
        function onArmCountChanged() {
            root.progress = Notifs.totalMs > 0 ? Notifs.remainingMs / Notifs.totalMs : 1
            drain.from = root.progress
            drain.duration = Notifs.remainingMs
            drain.restart()
        }
        function onTimerRunningChanged() {
            if (!Notifs.timerRunning)
                drain.stop()
        }
        function onReplyingChanged() {
            if (!Notifs.replying)
                replyInput.text = ""
        }
    }

    // ── icône ───────────────────────────────────────────────────────────────
    Rectangle {
        x: root.pad
        y: root.implicitHeight <= 72 ? Math.round((root.implicitHeight - height) / 2) : 12
        width: 36
        height: 36
        radius: 18
        color: Qt.alpha(root.tone, root.iconSource === "" ? 1.0 : 0.16)

        Text {
            anchors.centerIn: parent
            visible: root.iconSource === "" && !root.synthetic
            text: root.n && root.n.appName !== "" ? root.n.appName[0].toUpperCase() : "?"
            color: Theme.islandBg
            font.family: Theme.fontFamily
            font.pixelSize: 17
            font.weight: Theme.fontWeightStrong
        }

        MoonIcon {
            anchors.centerIn: parent
            visible: root.synthetic
            size: 18
            color: Theme.islandBg
        }

        IconImage {
            anchors.centerIn: parent
            implicitSize: 24
            visible: root.iconSource !== ""
            source: root.iconSource
        }
    }

    // ── texte ───────────────────────────────────────────────────────────────
    Column {
        id: main
        x: root.textX
        y: root.implicitHeight <= 72 ? Math.round((root.implicitHeight - implicitHeight) / 2) : 12
        width: root.textWidth
        spacing: 2

        // application et heure
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: {
                if (!root.n)
                    return ""
                const app = root.n.appName !== "" ? root.n.appName : "Notification"
                if (root.grp.length > 1)
                    return app + ", " + root.grp.length + " notifications"
                if (root.synthetic)
                    return app
                return app + ", " + Notifs.ago(Notifs.timeOf(root.n), Time.now)
            }
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall - 1
            font.weight: Theme.fontWeight
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.n?.summary ?? ""
            color: root.critical ? Theme.critical : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
            font.weight: Theme.fontWeightStrong
        }

        Text {
            width: parent.width
            visible: text !== ""
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: root.hovered ? Settings.notifBodyLinesHovered : Settings.notifBodyLines
            text: root.n ? Notifs.richBody(root.n.body) : ""
            textFormat: Text.StyledText
            linkColor: Theme.secondary
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            onLinkActivated: link => Qt.openUrlExternally(link)
        }

        // groupe : les deux précédentes, une ligne chacune
        Column {
            width: parent.width
            visible: root.grp.length > 1
            topPadding: 4
            spacing: 2

            Repeater {
                model: root.grp.length > 1 ? root.grp.slice(Math.max(0, root.grp.length - 3), root.grp.length - 1).reverse() : []

                Text {
                    required property var modelData
                    width: parent.width
                    elide: Text.ElideRight
                    textFormat: Text.StyledText
                    text: "<b>" + Notifs.richBody(modelData.summary) + "</b>  "
                          + Notifs.richBody(Notifs.plainText(modelData.body))
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }

        // boutons d'action
        Flow {
            width: parent.width
            visible: root.actions.length > 0
            topPadding: 6
            spacing: 6

            Repeater {
                model: root.actions

                Rectangle {
                    id: chip
                    required property var modelData
                    required property int index
                    height: 26
                    width: chipText.implicitWidth + 24
                    radius: 13
                    color: index === 0
                        ? (chipMouse.containsMouse ? Theme.secondary : Theme.accent)
                        : (chipMouse.containsMouse ? Theme.surfaceHover : Theme.surface)
                    Behavior on color { ColorAnimation { duration: 110 } }

                    Text {
                        id: chipText
                        anchors.centerIn: parent
                        text: chip.modelData.text
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Theme.fontWeightStrong
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.invokeAction(root.n, chip.modelData)
                    }
                }
            }
        }

        // réponse rapide
        Item {
            width: parent.width
            height: 36
            visible: root.canReply

            Rectangle {
                id: replyField
                anchors.left: parent.left
                anchors.right: sendBtn.left
                anchors.rightMargin: 6
                anchors.bottom: parent.bottom
                height: 30
                radius: 15
                color: Theme.surface
                border.width: replyInput.activeFocus ? 1 : 0
                border.color: Theme.surfaceHover

                TextInput {
                    id: replyInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    color: Theme.fg
                    selectionColor: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall

                    onAccepted: Notifs.sendReply(root.n, text)
                    Keys.onEscapePressed: {
                        text = ""
                        Notifs.replying = false
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: replyInput.text === ""
                        text: root.n && root.n.inlineReplyPlaceholder ? root.n.inlineReplyPlaceholder : "Répondre…"
                        color: Theme.fgDim
                        font: replyInput.font
                    }
                }

                // le clic demande le clavier à l'îlot, puis donne le focus
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    visible: !replyInput.activeFocus
                    onClicked: {
                        Notifs.replying = true
                        replyFocus.restart()
                    }
                }

                Timer {
                    id: replyFocus
                    interval: 80
                    onTriggered: replyInput.forceActiveFocus()
                }
            }

            IslandButton {
                id: sendBtn
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                implicitWidth: 30
                implicitHeight: 30
                baseColor: Theme.accent
                enabled: replyInput.text !== ""
                onClicked: Notifs.sendReply(root.n, replyInput.text)
                BackIcon {
                    anchors.centerIn: parent
                    size: 14
                    strokeWidth: 2.2
                    rotation: 180
                    color: Theme.fg
                }
            }
        }
    }

    // ── à droite : vignette, file d'attente, croix ou pastille ──────────────
    Row {
        id: side
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        y: root.implicitHeight <= 72 ? Math.round((root.implicitHeight - height) / 2) : 12
        spacing: 8

        ClippingRectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showThumb
            width: 64
            height: 44
            radius: 8
            color: Theme.surface

            Image {
                anchors.fill: parent
                source: root.showThumb ? root.imageSource : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(128, 88)
            }
        }

        // « +N » : notifications en attente ; clic = suivante, molette = tout passer
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.queued > 0
            height: 22
            width: Math.max(22, queueText.implicitWidth + 12)
            radius: 11
            color: queueMouse.containsMouse ? Theme.surfaceHover : Theme.surface

            Text {
                id: queueText
                anchors.centerIn: parent
                text: "+" + root.queued
                color: Theme.icon
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall - 1
                font.weight: Theme.fontWeightStrong
            }

            MouseArea {
                id: queueMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouseEvent => {
                    if (mouseEvent.button === Qt.MiddleButton)
                        Notifs.clearQueue()
                    else
                        Notifs.hideCurrent()
                }
            }
        }

        // critique : reste jusqu'à la croix (ou un clic)
        IslandButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.critical
            implicitWidth: 24
            implicitHeight: 24
            baseColor: Theme.surface
            onClicked: Notifs.hideCurrent()
            CloseIcon { anchors.centerIn: parent; size: 10; color: Theme.icon }
        }

        // pastille d'urgence (rien d'autre à droite)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.showThumb && root.queued === 0 && !root.critical
            width: 7
            height: 7
            radius: 3.5
            color: root.tone
        }
    }

    // barre du temps restant (masquée pour les critiques, sans limite)
    Rectangle {
        x: 22
        y: root.implicitHeight - 3
        height: 2
        radius: 1
        width: Math.max(0, (root.implicitWidth - 44) * root.progress)
        visible: Notifs.totalMs > 0
        color: Notifs.paused ? Theme.powerRestart : root.tone
        opacity: 0.85
    }
}
