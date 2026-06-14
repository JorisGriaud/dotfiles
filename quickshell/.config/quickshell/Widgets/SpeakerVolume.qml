import QtQuick
import qs.Config
import qs.Services
import qs.Icons

/**
 * Haut-parleur + pourcentage du volume courant (vue au repos,
 * à droite de l'heure quand un média est présent).
 */
Row {
    id: root

    property color color: Theme.accent
    property real iconSize: 14

    spacing: 4

    SpeakerIcon {
        anchors.verticalCenter: parent.verticalCenter
        size: root.iconSize
        volume: Audio.volume
        muted: Audio.muted
        color: root.color
    }

    /*Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(Audio.volume * 100) + "%"
        color: Theme.accent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Theme.fontWeight
    }*/
}
