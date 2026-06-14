import QtQuick
import qs.Config
import qs.Core

/**
 * Barre de progression interactive : remplissage fluide (ressort) + rond
 * draggable à la souris. Clic n'importe où sur la piste = saut à la valeur.
 *
 *   KnobSlider { value: Audio.volume; onMoved: v => Audio.setVolume(v) }
 *
 * `moved(v)` est émis en continu pendant le drag, `released(v)` au relâché
 * (utile pour les cibles coûteuses comme brightnessctl).
 */
Item {
    id: root

    property real value: 0              // 0..1 (valeur externe affichée)
    property color fillColor: Theme.accent
    property color trackColor: Theme.surfaceHover
    property real trackHeight: 5
    property real knobSize: 14

    signal moved(real v)
    signal released(real v)

    implicitHeight: Math.max(knobSize + 4, trackHeight)
    implicitWidth: 150

    // pendant le drag on suit la souris, sinon la valeur externe
    CriticalSpring {
        id: spring
        speed: Theme.springNormal
        target: mouse.pressed ? mouse.dragValue
                              : Math.max(0, Math.min(1, root.value))
    }

    readonly property real shown: Math.max(0, Math.min(1, spring.value))

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackHeight
        radius: height / 2
        color: root.trackColor
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(track.height, track.width * root.shown)
        height: track.height
        radius: height / 2
        color: root.fillColor
    }

    Rectangle {
        id: knob
        anchors.verticalCenter: parent.verticalCenter
        x: root.shown * (parent.width - width)
        width: root.knobSize
        height: root.knobSize
        radius: width / 2
        color: Theme.fg
        border.color: Qt.alpha("#000000", 0.25)
        border.width: 1
        scale: mouse.pressed ? 1.18 : (mouse.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        property real dragValue: 0

        function valueAt(mx) {
            // aligné sur la course du rond (knobSize/2 de marge de chaque côté)
            const usable = width - root.knobSize
            return Math.max(0, Math.min(1, (mx - root.knobSize / 2) / Math.max(1, usable)))
        }

        onPressed: mouseEvent => {
            dragValue = valueAt(mouseEvent.x)
            root.moved(dragValue)
        }
        onPositionChanged: mouseEvent => {
            if (pressed) {
                dragValue = valueAt(mouseEvent.x)
                root.moved(dragValue)
            }
        }
        onReleased: root.released(dragValue)
    }
}
