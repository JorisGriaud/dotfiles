import QtQuick
import QtQuick.Shapes

/**
 * Photo encadrée — fond d'écran.
 */
Icon {
    id: root

    Rectangle {
        x: 2.6; y: 4.4; width: 18.8; height: 15.2
        radius: 3
        color: "transparent"
        border.color: root.color
        border.width: root.strokeWidth
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // soleil
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: root.color
            PathAngleArc {
                centerX: 8.4; centerY: 9.4
                radiusX: 1.7; radiusY: 1.7
                startAngle: 0; sweepAngle: 360
            }
        }

        // relief
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 4.4; startY: 17.4
            PathLine { x: 10; y: 11.8 }
            PathLine { x: 14.2; y: 16 }
            PathLine { x: 16.4; y: 13.8 }
            PathLine { x: 19.6; y: 17 }
        }
    }
}
