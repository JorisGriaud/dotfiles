import QtQuick
import QtQuick.Shapes

/**
 * Rune Bluetooth.
 */
Icon {
    id: root

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 7; startY: 7.5
            PathLine { x: 17; y: 16.5 }
            PathLine { x: 12; y: 20.5 }
            PathLine { x: 12; y: 3.5 }
            PathLine { x: 17; y: 7.5 }
            PathLine { x: 7; y: 16.5 }
        }
    }
}
