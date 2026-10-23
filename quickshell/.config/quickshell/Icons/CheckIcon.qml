import QtQuick
import QtQuick.Shapes

/**
 * Coche — action réussie.
 */
Icon {
    id: root

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: root.strokeWidth + 0.3
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 4.8; startY: 12.6
            PathLine { x: 9.8; y: 17.6 }
            PathLine { x: 19.4; y: 6.6 }
        }
    }
}
