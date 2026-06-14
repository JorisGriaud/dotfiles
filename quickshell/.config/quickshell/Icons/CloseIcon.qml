import QtQuick
import QtQuick.Shapes

/**
 * Croix de fermeture.
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
            startX: 6.5; startY: 6.5
            PathLine { x: 17.5; y: 17.5 }
            PathMove { x: 17.5; y: 6.5 }
            PathLine { x: 6.5; y: 17.5 }
        }
    }
}
