import QtQuick
import qs.Config
import qs.Services
import qs.Widgets

/**
 * État au repos : barres d'égaliseur (si lecture), l'heure, et le volume
 * (haut-parleur + %) dès qu'un média est présent.
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

        /*SpeakerVolume {
            anchors.verticalCenter: parent.verticalCenter
            visible: Media.hasPlayer
        }*/
    }
}
