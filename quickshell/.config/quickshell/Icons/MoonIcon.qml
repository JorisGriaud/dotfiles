import QtQuick
import QtQuick.Shapes

/**
 * Lune (Ne pas déranger, mode nuit) : croissant épais découpé par un
 * second cercle décalé en haut à droite, plus une petite étoile.
 *
 * Géométrie (canevas 24×24) :
 *   cercle extérieur  C1 = (11, 12), r = 9
 *   cercle de découpe C2 = (16, 7),  r = 7,5
 *   intersections     A ≈ (9,59 ; 3,11) en haut, B ≈ (19,89 ; 13,41) à droite
 */
Icon {
    id: root

    property bool sparkle: true

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // croissant : grand arc du cercle extérieur, puis retour par le
        // cercle de découpe (côté intérieur, bombé vers le bas à gauche)
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: root.color
            startX: 9.587; startY: 3.111
            PathArc {
                x: 19.889; y: 13.413
                radiusX: 9; radiusY: 9
                useLargeArc: true
                direction: PathArc.Counterclockwise
            }
            PathArc {
                x: 9.587; y: 3.111
                radiusX: 7.5; radiusY: 7.5
                useLargeArc: true
                direction: PathArc.Clockwise
            }
        }

        // petite étoile à quatre branches, dans le creux
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: root.sparkle ? root.color : "transparent"
            startX: 19.6; startY: 1.6
            PathQuad { x: 21.9; y: 3.9; controlX: 19.9; controlY: 3.6 }
            PathQuad { x: 19.6; y: 6.2; controlX: 19.9; controlY: 4.2 }
            PathQuad { x: 17.3; y: 3.9; controlX: 19.3; controlY: 4.2 }
            PathQuad { x: 19.6; y: 1.6; controlX: 19.3; controlY: 3.6 }
        }
    }
}
