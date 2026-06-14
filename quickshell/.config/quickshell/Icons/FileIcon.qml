import QtQuick
import QtQuick.Shapes

/**
 * Fichier (page au coin replié).
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
            joinStyle: ShapePath.RoundJoin
            startX: 13.6; startY: 3.6
            PathLine { x: 8; y: 3.6 }
            PathQuad { x: 6.5; y: 5.1; controlX: 6.5; controlY: 3.6 }
            PathLine { x: 6.5; y: 19 }
            PathQuad { x: 8; y: 20.5; controlX: 6.5; controlY: 20.5 }
            PathLine { x: 16; y: 20.5 }
            PathQuad { x: 17.5; y: 19; controlX: 17.5; controlY: 20.5 }
            PathLine { x: 17.5; y: 7.5 }
            PathLine { x: 13.6; y: 3.6 }
        }

        // pli du coin
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            startX: 13.6; startY: 3.6
            PathLine { x: 13.6; y: 7.5 }
            PathLine { x: 17.5; y: 7.5 }
        }
    }
}
