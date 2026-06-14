import QtQuick
import QtQuick.Shapes

/**
 * Dossier (mode "/" du lanceur : ouvrir un fichier).
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
            startX: 4.5; startY: 17
            PathLine { x: 4.5; y: 7 }
            PathQuad { x: 6; y: 5.5; controlX: 4.5; controlY: 5.5 }
            PathLine { x: 9.6; y: 5.5 }
            PathLine { x: 11.6; y: 8 }
            PathLine { x: 18; y: 8 }
            PathQuad { x: 19.5; y: 9.5; controlX: 19.5; controlY: 8 }
            PathLine { x: 19.5; y: 17 }
            PathQuad { x: 18; y: 18.5; controlX: 19.5; controlY: 18.5 }
            PathLine { x: 6; y: 18.5 }
            PathQuad { x: 4.5; y: 17; controlX: 4.5; controlY: 18.5 }
        }
    }
}
