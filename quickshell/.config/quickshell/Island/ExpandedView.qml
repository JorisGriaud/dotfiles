import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.Config
import qs.Services
import qs.Widgets
import qs.Icons

/**
 * État survolé/épinglé, fidèle à la maquette :
 *   gauche  : pochette + EQ + titre/artiste (affichage seul)
 *   centre  : grande horloge + date, VRAIMENT centrées dans la pilule
 *   droite  : pilule de statuts (réseau, ventilateur, volume, batterie/luminosité)
 *
 * Les icônes ne sont pas cliquables : ce sont les FONDS de zone qui le sont —
 * zones gauche/droite → centre de contrôle, zone horloge → calendrier.
 * Si une notification arrive pendant le survol, elle s'affiche en bas.
 */
IslandView {
    id: root

    readonly property bool showNotif: Notifs.current !== null
    readonly property int notifRowHeight: 34

    readonly property real sideMax: Math.max(leftZone.implicitWidth, rightZone.implicitWidth)

    implicitWidth: 2 * (sideMax + 18) + centerZone.implicitWidth + 2 * 16
    implicitHeight: Settings.expandedHeight + (showNotif ? notifRowHeight + 6 : 0)

    // bande supérieure : les trois zones
    Item {
        id: topRow
        anchors.top: parent.top
        width: parent.width
        height: Settings.expandedHeight

        // ── Zone gauche : média (affichage seul, clic → centre de contrôle) ─
        Rectangle {
            id: leftZone
            anchors.left: parent.left
            anchors.leftMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: mediaRow.implicitWidth + 16
            width: implicitWidth
            height: parent.height - 14
            radius: height / 2
            color: leftMouse.containsMouse ? Qt.alpha(Theme.surfaceHover, 0.45) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Row {
                id: mediaRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                spacing: 9

                ClippingRectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    height: 34
                    radius: 10
                    color: Theme.surface
                    visible: Media.artUrl !== ""

                    Image {
                        anchors.fill: parent
                        source: Media.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                EqBars {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Media.playing
                    playing: Media.playing
                    color: Theme.accent
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    visible: Media.hasPlayer

                    Text {
                        width: Math.min(implicitWidth, 130)
                        elide: Text.ElideRight
                        text: Media.title !== "" ? Media.title : "Sans titre"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Theme.fontWeightStrong
                    }

                    Text {
                        width: Math.min(implicitWidth, 130)
                        elide: Text.ElideRight
                        text: Media.artist
                        visible: Media.artist !== ""
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall - 1
                        font.weight: Theme.fontWeight
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !Media.hasPlayer
                    text: "Aucun média"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Theme.fontWeight
                }
            }

            MouseArea {
                id: leftMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: IslandState.togglePanel("control")
            }
        }

        // ── Zone centrale : horloge + date, centrées dans la pilule ─────────
        Rectangle {
            id: centerZone
            anchors.centerIn: parent
            implicitWidth: clockCol.implicitWidth + 24
            width: implicitWidth
            height: parent.height - 14
            radius: height / 2
            color: centerMouse.containsMouse ? Qt.alpha(Theme.surfaceHover, 0.45) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Column {
                id: clockCol
                anchors.centerIn: parent
                spacing: 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Time.time
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeClock
                    font.weight: Theme.fontWeightStrong
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Time.longDate
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Theme.fontWeight
                }
            }

            MouseArea {
                id: centerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: IslandState.togglePanel("calendar")
            }
        }

        // ── Zone droite : statuts système (clic → centre de contrôle) ───────
        Rectangle {
            id: rightZone
            anchors.right: parent.right
            anchors.rightMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: statusRow.implicitWidth + 26
            width: implicitWidth
            height: 36
            radius: 18
            color: rightMouse.containsMouse ? Theme.surfaceHover : Theme.surface
            Behavior on color { ColorAnimation { duration: 120 } }

            Row {
                id: statusRow
                anchors.centerIn: parent
                spacing: 12

                // réseau : ethernet branché sinon jauge wifi
                EthernetIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Network.wiredConnected
                    size: 16
                    color: Theme.accent
                }

                WifiIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !Network.wiredConnected
                    size: 16
                    strength: Network.strength
                    connected: Network.wifiConnected
                    color: Network.wifiConnected ? Theme.accent : Theme.fgDim
                }

                FanIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Fan.available
                    size: 16
                    rpm: Fan.rpm
                    color: Theme.icon
                }

                SpeakerIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 16
                    volume: Audio.volume
                    muted: Audio.muted
                    color: Theme.accent
                }

                BatteryIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Battery.available
                    size: 13
                    level: Battery.level
                    charging: Battery.charging
                }

                SunIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Brightness.available
                    size: 16
                    level: Brightness.level
                    color: Theme.fg
                }
            }

            MouseArea {
                id: rightMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: IslandState.togglePanel("control")
            }
        }
    }

    // ── Notification en ligne, en bas de la vue étendue ─────────────────────
    Rectangle {
        id: notifRow
        anchors.top: topRow.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 24
        height: root.notifRowHeight
        radius: 12
        visible: root.showNotif
        color: notifMouse.containsMouse ? Qt.alpha(Theme.surfaceHover, 0.55) : Theme.surface

        readonly property bool critical: Notifs.current !== null
            && Notifs.current.urgency === NotificationUrgency.Critical

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: bellBtn.left
            anchors.rightMargin: 6
            spacing: 8

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 7; height: 7; radius: 3.5
                color: notifRow.critical ? Theme.critical : Theme.accent
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 170)
                elide: Text.ElideRight
                text: Notifs.current?.summary ?? ""
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Theme.fontWeightStrong
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth,
                                parent.width - 200)
                elide: Text.ElideRight
                text: Notifs.current?.body ?? ""
                textFormat: Text.PlainText
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Theme.fontWeight
            }
        }

        // clic = ouvrir, molette (clic central) = fermer
        MouseArea {
            id: notifMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouseEvent => {
                if (mouseEvent.button === Qt.MiddleButton)
                    Notifs.dismissCurrent()
                else
                    Notifs.activateCurrent()
            }
        }

        // bascule rapide du mode Ne pas déranger
        IslandButton {
            id: bellBtn
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 26
            implicitHeight: 26
            onClicked: Notifs.togglePeace()

            BellIcon {
                anchors.centerIn: parent
                size: 14
                silenced: Notifs.peace
                color: Theme.fg
            }
        }
    }
}
