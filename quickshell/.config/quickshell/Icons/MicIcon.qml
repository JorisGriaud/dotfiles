import QtQuick
import QtQuick.Shapes

/**
 * Microphone (volume d'entrée).
 */
Icon {
    id: root

    property bool muted: false

    // capsule
    Rectangle {
        x: 9.2
        y: 3
        width: 5.6
        height: 10.5
        radius: 2.8
        color: root.color
        opacity: root.muted ? 0.45 : 1.0
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        opacity: root.muted ? 0.45 : 1.0

        // arceau
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: 12; centerY: 12.2
                radiusX: 5.6; radiusY: 5.6
                startAngle: 0; sweepAngle: 180
            }
        }

        // pied
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 12; startY: 17.8
            PathLine { x: 12; y: 20.5 }
            PathMove { x: 8.6; y: 20.5 }
            PathLine { x: 15.4; y: 20.5 }
        }
    }

    // barre de sourdine
    Shape {
        anchors.fill: parent
        visible: root.muted
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 5.5; startY: 4.5
            PathLine { x: 18.5; y: 19 }
        }
    }
}
