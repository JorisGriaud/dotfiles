import QtQuick
import QtQuick.Shapes

/**
 * Cadenas (authentification Polkit).
 */
Icon {
    id: root

    // anse
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 8.2; startY: 11
            PathLine { x: 8.2; y: 8.4 }
            PathArc { x: 15.8; y: 8.4; radiusX: 3.8; radiusY: 3.8 }
            PathLine { x: 15.8; y: 11 }
        }
    }

    // corps
    Rectangle {
        x: 6
        y: 10.6
        width: 12
        height: 9.4
        radius: 2.2
        color: root.color
    }

    // trou de serrure
    Rectangle {
        x: 11.1
        y: 13.4
        width: 1.8
        height: 3.8
        radius: 0.9
        color: "#00000055"
    }
}
