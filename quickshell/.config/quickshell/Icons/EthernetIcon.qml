import QtQuick
import QtQuick.Shapes

/**
 * Connecteur Ethernet (RJ45) — affiché à la place du Wi-Fi en filaire.
 */
Icon {
    id: root

    // corps du connecteur
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            startX: 6; startY: 8.2
            PathLine { x: 6; y: 5.8 }
            PathQuad { x: 7.4; y: 4.4; controlX: 6; controlY: 4.4 }
            PathLine { x: 16.6; y: 4.4 }
            PathQuad { x: 18; y: 5.8; controlX: 18; controlY: 4.4 }
            PathLine { x: 18; y: 8.2 }
            PathLine { x: 15.6; y: 8.2 }
            PathLine { x: 15.6; y: 10.4 }
            PathLine { x: 8.4; y: 10.4 }
            PathLine { x: 8.4; y: 8.2 }
            PathLine { x: 6; y: 8.2 }
        }
    }

    // broches
    Rectangle { x: 9.1;  y: 4.4; width: 1.4; height: 2.6; color: root.color }
    Rectangle { x: 11.3; y: 4.4; width: 1.4; height: 2.6; color: root.color }
    Rectangle { x: 13.5; y: 4.4; width: 1.4; height: 2.6; color: root.color }

    // câble
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 12; startY: 10.4
            PathLine { x: 12; y: 15 }
            PathQuad { x: 9.5; y: 17.5; controlX: 12; controlY: 17.5 }
            PathLine { x: 7.5; y: 17.5 }
            PathQuad { x: 5; y: 20; controlX: 5; controlY: 17.5 }
        }
    }
}
