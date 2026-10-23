import QtQuick
import qs.Config
import qs.Services
import qs.Widgets
import qs.Icons

/**
 * État au repos : barres d'égaliseur (si lecture), l'heure, et une pastille
 * pour les notifications pas encore vues (lune en Ne pas déranger). La
 * pastille disparaît à l'ouverture du centre de contrôle.
 */
IslandView {
    id: root

    implicitWidth: row.implicitWidth + 2 * Settings.contentPadding + 8
    implicitHeight: Settings.restHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        EqBars {
            anchors.verticalCenter: parent.verticalCenter
            playing: Media.playing
            visible: Settings.eqBarsEnabled && Media.playing
            color: Theme.accent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.time
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
            font.weight: Theme.fontWeightStrong
        }

        // Ne pas déranger : lune seule, à la taille du texte
        MoonIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: Notifs.peace
            size: 18
            color: Theme.powerRestart
        }

        // notifications non vues (grise pendant Ne pas déranger)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: Notifs.unread > 0
            height: 20
            width: Math.max(20, unreadText.implicitWidth + 12)
            radius: 10
            color: Notifs.peace ? Theme.surface : Theme.accent

            Text {
                id: unreadText
                anchors.centerIn: parent
                text: Notifs.unread > 99 ? "99+" : Notifs.unread
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall - 1
                font.weight: Theme.fontWeightStrong
            }
        }

        /*SpeakerVolume {
            anchors.verticalCenter: parent.verticalCenter
            visible: Media.hasPlayer
        }*/
    }
}
