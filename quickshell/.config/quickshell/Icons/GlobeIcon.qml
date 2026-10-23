import QtQuick
import QtQuick.Shapes

/**
 * Globe — réseau (indépendant du média : Wi-Fi ou Ethernet).
 */
Icon {
    id: root

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // sphère
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            PathAngleArc {
                centerX: 12; centerY: 12
                radiusX: 8.8; radiusY: 8.8
                startAngle: 0; sweepAngle: 360
            }
        }

        // équateur
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 3.2; startY: 12
            PathLine { x: 20.8; y: 12 }
        }

        // méridiens (deux arcs symétriques du pôle nord au pôle sud)
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 12; startY: 3.2
            PathCubic { x: 12; y: 20.8; control1X: 16.4; control1Y: 7.4; control2X: 16.4; control2Y: 16.6 }
            PathMove { x: 12; y: 3.2 }
            PathCubic { x: 12; y: 20.8; control1X: 7.6; control1Y: 7.4; control2X: 7.6; control2Y: 16.6 }
        }
    }
}
