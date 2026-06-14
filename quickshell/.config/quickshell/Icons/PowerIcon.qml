import QtQuick
import QtQuick.Shapes

/**
 * Bouton d'alimentation (arc ouvert en haut + barre verticale).
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
            PathAngleArc {
                centerX: 12; centerY: 13
                radiusX: 7; radiusY: 7
                startAngle: 305; sweepAngle: 290
            }
        }

        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 12; startY: 3.2
            PathLine { x: 12; y: 11.5 }
        }
    }
}
