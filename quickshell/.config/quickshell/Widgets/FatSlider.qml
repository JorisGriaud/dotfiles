import QtQuick
import qs.Config
import qs.Core

/**
 * Barre de réglage épaisse, fidèle à la maquette du centre de contrôle :
 * piste sombre pleine hauteur, remplissage arrondi, icône posée À L'INTÉRIEUR
 * du remplissage (slot `iconContent`). Toute la barre est draggable ;
 * le rond de prise n'apparaît qu'au survol pour garder le look épuré.
 *
 *   FatSlider {
 *       value: Audio.volume
 *       onMoved: v => Audio.setVolume(v)
 *       SpeakerIcon { anchors.centerIn: parent; ... color: Theme.islandBg }
 *   }
 */
Item {
    id: root

    property real value: 0              // 0..1
    property color fillColor: Theme.accent
    property color trackColor: Theme.surface

    signal moved(real v)
    signal released(real v)

    default property alias iconContent: iconSlot.data

    implicitHeight: 28
    implicitWidth: 200

    CriticalSpring {
        id: spring
        speed: Theme.springNormal
        target: mouse.pressed ? mouse.dragValue
                              : Math.max(0, Math.min(1, root.value))
    }

    readonly property real shown: Math.max(0, Math.min(1, spring.value))

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.trackColor
    }

    // remplissage : jamais plus court qu'un cercle, pour que l'icône
    // reste posée dessus même à 0 %
    Rectangle {
        id: fill
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(height, parent.width * root.shown)
        height: parent.height
        radius: height / 2
        color: root.fillColor
        Behavior on color { ColorAnimation { duration: Theme.fadeDuration } }
    }

    Item {
        id: iconSlot
        anchors.left: parent.left
        anchors.leftMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        height: 18
    }

    // rond de prise, discret : visible au survol / pendant le drag
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(4, fill.width - width - 4)
        width: 14
        height: 14
        radius: 7
        color: Theme.fg
        border.color: Qt.alpha("#000000", 0.25)
        border.width: 1
        opacity: mouse.containsMouse || mouse.pressed ? 1 : 0
        scale: mouse.pressed ? 1.15 : 1.0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        property real dragValue: 0

        function valueAt(mx) {
            return Math.max(0, Math.min(1, mx / Math.max(1, width)))
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
