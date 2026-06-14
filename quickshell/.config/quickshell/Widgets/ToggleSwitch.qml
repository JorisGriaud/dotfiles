import QtQuick
import qs.Config

/**
 * Interrupteur pilule (style iOS) — en-tête des pages Wi-Fi / Bluetooth.
 */
Item {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 44
    implicitHeight: 24

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.surfaceHover
        Behavior on color { ColorAnimation { duration: Theme.fadeDuration } }
    }

    Rectangle {
        id: knob
        width: 18
        height: 18
        radius: 9
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 3 : 3
        color: Theme.fg
        scale: mouse.containsMouse ? 1.08 : 1.0
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
