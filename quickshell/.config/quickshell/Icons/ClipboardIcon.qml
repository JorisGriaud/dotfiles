import QtQuick
import QtQuick.Shapes

/**
 * Presse-papiers (mode ":" du lanceur).
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
            startX: 8.5; startY: 5
            PathLine { x: 6.5; y: 5 }
            PathQuad { x: 5; y: 6.5; controlX: 5; controlY: 5 }
            PathLine { x: 5; y: 19 }
            PathQuad { x: 6.5; y: 20.5; controlX: 5; controlY: 20.5 }
            PathLine { x: 17.5; y: 20.5 }
            PathQuad { x: 19; y: 19; controlX: 19; controlY: 20.5 }
            PathLine { x: 19; y: 6.5 }
            PathQuad { x: 17.5; y: 5; controlX: 19; controlY: 5 }
            PathLine { x: 15.5; y: 5 }
        }
    }

    // agrafe
    Rectangle {
        x: 8.8
        y: 3.2
        width: 6.4
        height: 3.6
        radius: 1.4
        color: root.color
    }

    // lignes de contenu
    Rectangle { x: 8; y: 10.5; width: 8; height: 1.6; radius: 0.8; color: root.color; opacity: 0.6 }
    Rectangle { x: 8; y: 14;   width: 8; height: 1.6; radius: 0.8; color: root.color; opacity: 0.6 }
    Rectangle { x: 8; y: 17.5; width: 5; height: 1.6; radius: 0.8; color: root.color; opacity: 0.6 }
}
