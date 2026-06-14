import QtQuick
import qs.Config
import qs.Core

/**
 * Barre de progression fine et fluide (remplissage par ressort).
 */
Item {
    id: root

    property real value: 0          // 0..1
    property color fillColor: Theme.accent
    property color trackColor: Theme.surfaceHover

    implicitHeight: 5
    implicitWidth: 120

    CriticalSpring {
        id: spring
        speed: Theme.springNormal
        target: Math.max(0, Math.min(1, root.value))
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.trackColor
    }

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(height, parent.width * spring.value)
        height: parent.height
        radius: height / 2
        color: root.fillColor
    }
}
