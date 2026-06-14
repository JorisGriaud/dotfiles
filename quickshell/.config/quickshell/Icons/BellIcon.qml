import QtQuick
import QtQuick.Shapes
import qs.Config

/**
 * Cloche de notifications. `silenced` = mode "Peace" (ne pas déranger) :
 * la cloche s'estompe et une barre la traverse.
 */
Icon {
    id: root

    property bool silenced: false

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        opacity: root.silenced ? 0.45 : 1.0
        Behavior on opacity { NumberAnimation { duration: Theme.fadeDuration } }

        // corps de la cloche
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            startX: 5; startY: 15.6
            PathLine { x: 6.2; y: 14.2 }
            PathQuad { x: 6.9; y: 12.4; controlX: 6.9; controlY: 13.4 }
            PathLine { x: 6.9; y: 8.8 }
            PathQuad { x: 12; y: 3.4; controlX: 6.9; controlY: 3.4 }
            PathQuad { x: 17.1; y: 8.8; controlX: 17.1; controlY: 3.4 }
            PathLine { x: 17.1; y: 12.4 }
            PathQuad { x: 17.8; y: 14.2; controlX: 17.1; controlY: 13.4 }
            PathLine { x: 19; y: 15.6 }
            PathLine { x: 5; y: 15.6 }
        }

        // battant
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: 12; centerY: 17.4
                radiusX: 2.1; radiusY: 2.1
                startAngle: 25; sweepAngle: 130
            }
        }
    }

    // barre du mode silencieux
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: Qt.alpha(Theme.critical, root.silenced ? 1.0 : 0.0)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            Behavior on strokeColor { ColorAnimation { duration: Theme.fadeDuration } }
            startX: 5; startY: 4.5
            PathLine { x: 19.5; y: 19 }
        }
    }
}
