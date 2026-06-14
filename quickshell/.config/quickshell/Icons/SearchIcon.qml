import QtQuick
import QtQuick.Shapes

/**
 * Loupe de recherche.
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
            PathAngleArc {
                centerX: 10.5; centerY: 10.5
                radiusX: 5.6; radiusY: 5.6
                startAngle: 0; sweepAngle: 360
            }
        }

        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 14.8; startY: 14.8
            PathLine { x: 19.4; y: 19.4 }
        }
    }
}
