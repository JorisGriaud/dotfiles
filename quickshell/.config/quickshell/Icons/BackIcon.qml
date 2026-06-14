import QtQuick
import QtQuick.Shapes

/**
 * Chevron retour (en-tête du centre de contrôle).
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
            joinStyle: ShapePath.RoundJoin
            startX: 14.5; startY: 6
            PathLine { x: 9; y: 12 }
            PathLine { x: 14.5; y: 18 }
        }
    }
}
