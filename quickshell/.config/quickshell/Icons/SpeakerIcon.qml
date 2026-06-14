import QtQuick
import QtQuick.Shapes
import qs.Config

/**
 * Icône haut-parleur dynamique :
 *  - 1 onde si volume faible, 2 ondes si volume fort
 *  - une croix (rouge) si muet
 */
Icon {
    id: root

    property real volume: 0
    property bool muted: false

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // corps du haut-parleur (rectangle + pavillon), rempli
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: root.color
            startX: 3; startY: 9
            PathLine { x: 7; y: 9 }
            PathLine { x: 12; y: 4.5 }
            PathLine { x: 12; y: 19.5 }
            PathLine { x: 7; y: 15 }
            PathLine { x: 3; y: 15 }
            PathLine { x: 3; y: 9 }
        }

        // onde 1 — volume > 0
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: Qt.alpha(root.color, (!root.muted && root.volume > 0.01) ? 1.0 : 0.0)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            Behavior on strokeColor { ColorAnimation { duration: Theme.fadeDuration } }
            PathAngleArc {
                centerX: 12.5; centerY: 12
                radiusX: 4.4; radiusY: 4.4
                startAngle: -52; sweepAngle: 104
            }
        }

        // onde 2 — volume fort
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: Qt.alpha(root.color, (!root.muted && root.volume >= 0.55) ? 1.0 : 0.0)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            Behavior on strokeColor { ColorAnimation { duration: Theme.fadeDuration } }
            PathAngleArc {
                centerX: 12.5; centerY: 12
                radiusX: 8.0; radiusY: 8.0
                startAngle: -52; sweepAngle: 104
            }
        }

        // croix de sourdine
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: Qt.alpha(Theme.critical, root.muted ? 1.0 : 0.0)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            Behavior on strokeColor { ColorAnimation { duration: Theme.fadeDuration } }
            startX: 15; startY: 8.5
            PathLine { x: 21; y: 15.5 }
            PathMove { x: 21; y: 8.5 }
            PathLine { x: 15; y: 15.5 }
        }
    }
}
