import QtQuick
import QtQuick.Shapes

/**
 * Flèche circulaire (redémarrer).
 */
Icon {
    id: root

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // cercle ouvert en haut à droite
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: 12; centerY: 12.5
                radiusX: 7; radiusY: 7
                startAngle: 320; sweepAngle: -280
            }
        }

        // pointe de flèche à l'extrémité de l'arc
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: root.color
            joinStyle: ShapePath.RoundJoin
            startX: 14.6; startY: 8.6
            PathLine { x: 21.2; y: 8.0 }
            PathLine { x: 17.6; y: 3.4 }
            PathLine { x: 14.6; y: 8.6 }
        }
    }
}
