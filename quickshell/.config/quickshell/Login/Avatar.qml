import QtQuick
import Quickshell.Widgets
import qs.Config

/**
 * Avatar rond : la photo si on en trouve une, sinon l'initiale sur un
 * dégradé accent → success.
 */
ClippingRectangle {
    id: root

    property string label: ""
    property var sources: []
    property real size: 48

    implicitWidth: size
    implicitHeight: size
    radius: size / 2

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.accent }
            GradientStop { position: 1; color: Theme.success }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: photo.status !== Image.Ready
        text: root.label.charAt(0).toUpperCase()
        color: Theme.fg
        font.family: Theme.fontFamily
        font.weight: Theme.fontWeightStrong
        font.pixelSize: root.size * 0.42
    }

    FallbackImage {
        id: photo
        anchors.fill: parent
        sources: root.sources
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        visible: status === Image.Ready
    }
}
