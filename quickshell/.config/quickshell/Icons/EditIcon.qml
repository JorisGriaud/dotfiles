import QtQuick
import QtQuick.Shapes

/**
 * Crayon (renommer).
 */
Icon {
    id: root

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // corps du crayon
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            startX: 14.5; startY: 5.5
            PathLine { x: 18.5; y: 9.5 }
            PathLine { x: 8; y: 20 }
            PathLine { x: 4; y: 20 }
            PathLine { x: 4; y: 16 }
            PathLine { x: 14.5; y: 5.5 }
        }

        // tête (partie biseautée)
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 12.5; startY: 7.5
            PathLine { x: 16.5; y: 11.5 }
        }
    }
}
