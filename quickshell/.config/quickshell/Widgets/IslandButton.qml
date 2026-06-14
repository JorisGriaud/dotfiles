import QtQuick
import qs.Config

/**
 * Bouton rond de l'îlot : halo au survol, consomme le clic
 * (un clic sur un bouton ne doit jamais épingler/désépingler l'îlot).
 */
Item {
    id: root

    signal clicked()

    property bool enabled: true
    readonly property bool hovered: mouse.containsMouse

    // fond permanent du bouton (ex. cercle visible autour du bouton retour)
    property color baseColor: "transparent"

    default property alias content: inner.data

    implicitWidth: 30
    implicitHeight: 30
    opacity: enabled ? 1 : 0.35

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.enabled && mouse.containsMouse ? Theme.surfaceHover : root.baseColor
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Item {
        id: inner
        anchors.fill: parent
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.enabled) root.clicked()
    }
}
