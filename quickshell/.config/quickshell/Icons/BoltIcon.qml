import QtQuick
import QtQuick.Shapes
import qs.Config

/**
 * Éclair (charge batterie). `outlineColor` permet un liseré pour
 * rester lisible posé sur un remplissage coloré.
 */
Icon {
    id: root

    property color outlineColor: "transparent"

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: root.outlineColor.a > 0 ? 1.4 : 0
            strokeColor: root.outlineColor
            fillColor: root.color
            joinStyle: ShapePath.RoundJoin
            startX: 13.2; startY: 2.5
            PathLine { x: 5.5; y: 13.2 }
            PathLine { x: 10.8; y: 13.2 }
            PathLine { x: 9.6; y: 21.5 }
            PathLine { x: 18.5; y: 9.8 }
            PathLine { x: 12.6; y: 9.8 }
            PathLine { x: 13.2; y: 2.5 }
        }
    }
}
