import QtQuick
import QtQuick.Shapes
import qs.Config
import qs.Core

/**
 * Icône soleil — les rayons s'allongent avec `level` ∈ [0,1] (luminosité).
 */
Icon {
    id: root

    property real level: 0.5

    readonly property real innerRadius: 6.4

    // longueur de rayon animée par ressort critiquement amorti
    CriticalSpring {
        id: raySpring
        speed: Theme.springSoft
        target: 2.0 + root.level * 3.6
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // disque central
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            PathAngleArc {
                centerX: 12; centerY: 12
                radiusX: 4.1; radiusY: 4.1
                startAngle: 0; sweepAngle: 360
            }
        }
    }

    // 8 rayons autour du disque
    Repeater {
        model: 8
        delegate: Rectangle {
            required property int index
            width: 2
            height: Math.max(0.5, raySpring.value)
            radius: 1
            color: root.color
            x: 12 - width / 2
            y: 12 - root.innerRadius - height
            transform: Rotation {
                origin.x: 1
                origin.y: root.innerRadius + height
                angle: index * 45
            }
        }
    }
}
