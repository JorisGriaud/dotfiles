import QtQuick
import qs.Config
import qs.Services
import qs.Widgets
import qs.Icons

/**
 * OSD volume / luminosité : icône dynamique + barre draggable (rond) + %.
 * Survoler l'OSD fige son chrono (le temps d'attraper le rond) ;
 * il disparaît tout seul ensuite et "fond" vers l'horloge.
 */
IslandView {
    id: root

    readonly property bool isVolume: IslandState.osdKind === "volume"
    readonly property real value: isVolume ? Audio.volume : Brightness.level

    implicitWidth: 280
    implicitHeight: 42

    Row {
        anchors.centerIn: parent
        spacing: 12

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20

            SpeakerIcon {
                anchors.centerIn: parent
                size: 20
                visible: root.isVolume
                volume: Audio.volume
                muted: Audio.muted
                color: Theme.fg
            }

            SunIcon {
                anchors.centerIn: parent
                size: 20
                visible: !root.isVolume
                level: Brightness.level
                color: Theme.fg
            }
        }

        KnobSlider {
            anchors.verticalCenter: parent.verticalCenter
            width: 150
            value: root.value
            fillColor: root.isVolume && Audio.muted ? Theme.fgDim : Theme.accent
            onMoved: v => {
                if (root.isVolume)
                    Audio.setVolume(v)
                else
                    Brightness.setLive(v)
            }
            onReleased: v => {
                if (!root.isVolume)
                    Brightness.set(v)   // valeur finale exacte
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            horizontalAlignment: Text.AlignRight
            text: Math.round(root.value * 100) + "%"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Theme.fontWeightStrong
        }
    }
}
