import QtQuick
import QtQuick.Shapes

/**
 * Calculatrice (mode "=" du lanceur).
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
            startX: 7; startY: 3.5
            PathLine { x: 17; y: 3.5 }
            PathQuad { x: 19; y: 5.5; controlX: 19; controlY: 3.5 }
            PathLine { x: 19; y: 18.5 }
            PathQuad { x: 17; y: 20.5; controlX: 19; controlY: 20.5 }
            PathLine { x: 7; y: 20.5 }
            PathQuad { x: 5; y: 18.5; controlX: 5; controlY: 20.5 }
            PathLine { x: 5; y: 5.5 }
            PathQuad { x: 7; y: 3.5; controlX: 5; controlY: 3.5 }
        }
    }

    // écran
    Rectangle { x: 7.6; y: 6.2; width: 8.8; height: 2.4; radius: 1; color: root.color }

    // touches
    Rectangle { x: 7.8;  y: 11;   width: 2.6; height: 2.6; radius: 1.3; color: root.color; opacity: 0.75 }
    Rectangle { x: 13.6; y: 11;   width: 2.6; height: 2.6; radius: 1.3; color: root.color; opacity: 0.75 }
    Rectangle { x: 7.8;  y: 15.6; width: 2.6; height: 2.6; radius: 1.3; color: root.color; opacity: 0.75 }
    Rectangle { x: 13.6; y: 15.6; width: 2.6; height: 2.6; radius: 1.3; color: root.color; opacity: 0.75 }
}
