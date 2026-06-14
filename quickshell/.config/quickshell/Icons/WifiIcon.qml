import QtQuick
import QtQuick.Shapes
import qs.Config

/**
 * Icône Wi-Fi — jauge de signal dynamique.
 * `strength` ∈ [0,1] allume progressivement les trois arcs ;
 * les arcs éteints restent visibles en filigrane.
 */
Icon {
    id: root

    property real strength: 0
    property bool connected: true

    readonly property real dimAlpha: 0.22

    function arcAlpha(threshold) {
        return (connected && strength >= threshold) ? 1.0 : dimAlpha
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // point central (toujours allumé si connecté)
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: Qt.alpha(root.color, root.connected ? 1.0 : root.dimAlpha)
            Behavior on fillColor { ColorAnimation { duration: Theme.fadeDuration } }
            PathAngleArc {
                centerX: 12; centerY: 18.6
                radiusX: 1.7; radiusY: 1.7
                startAngle: 0; sweepAngle: 360
            }
        }

        // arc 1 — signal faible
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: Qt.alpha(root.color, root.arcAlpha(0.20))
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            Behavior on strokeColor { ColorAnimation { duration: Theme.fadeDuration } }
            PathAngleArc {
                centerX: 12; centerY: 18.6
                radiusX: 5.4; radiusY: 5.4
                startAngle: 226; sweepAngle: 88
            }
        }

        // arc 2 — signal moyen
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: Qt.alpha(root.color, root.arcAlpha(0.55))
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            Behavior on strokeColor { ColorAnimation { duration: Theme.fadeDuration } }
            PathAngleArc {
                centerX: 12; centerY: 18.6
                radiusX: 9.0; radiusY: 9.0
                startAngle: 226; sweepAngle: 88
            }
        }

        // arc 3 — signal fort
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: Qt.alpha(root.color, root.arcAlpha(0.80))
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            Behavior on strokeColor { ColorAnimation { duration: Theme.fadeDuration } }
            PathAngleArc {
                centerX: 12; centerY: 18.6
                radiusX: 12.6; radiusY: 12.6
                startAngle: 226; sweepAngle: 88
            }
        }
    }
}
