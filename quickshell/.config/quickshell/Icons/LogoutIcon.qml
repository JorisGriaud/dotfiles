import QtQuick
import QtQuick.Shapes

/**
 * Déconnexion : porte + flèche sortante.
 */
Icon {
    id: root

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // cadre de porte
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 13.5; startY: 4
            PathLine { x: 7; y: 4 }
            PathQuad { x: 5.5; y: 5.5; controlX: 5.5; controlY: 4 }
            PathLine { x: 5.5; y: 18.5 }
            PathQuad { x: 7; y: 20; controlX: 5.5; controlY: 20 }
            PathLine { x: 13.5; y: 20 }
        }

        // flèche vers l'extérieur
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 10.5; startY: 12
            PathLine { x: 20; y: 12 }
            PathMove { x: 16.8; y: 8.8 }
            PathLine { x: 20; y: 12 }
            PathLine { x: 16.8; y: 15.2 }
        }
    }
}
