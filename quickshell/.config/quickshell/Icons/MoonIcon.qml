import QtQuick
import QtQuick.Shapes

/**
 * Croissant de lune (mode nuit / night light).
 */
Icon {
    id: root

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: root.color
            startX: 14.2; startY: 4.2
            // bord extérieur (grand arc, bombé à gauche)
            PathArc {
                x: 14.2; y: 19.8
                radiusX: 8.2; radiusY: 8.2
                useLargeArc: true
                direction: PathArc.Counterclockwise
            }
            // bord intérieur (petit arc, le creux du croissant)
            PathArc {
                x: 14.2; y: 4.2
                radiusX: 6.6; radiusY: 6.6
                useLargeArc: false
                direction: PathArc.Clockwise
            }
        }
    }
}
