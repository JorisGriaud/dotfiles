import QtQuick
import QtQuick.Shapes
import qs.Config

/**
 * Icônes de contrôle média : kind ∈ "play" | "pause" | "prev" | "next".
 */
Icon {
    id: root

    property string kind: "play"

    // ── lecture ─────────────────────────────────────────────────────────────
    Shape {
        anchors.fill: parent
        visible: root.kind === "play"
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: 0; strokeColor: "transparent"
            fillColor: root.color
            joinStyle: ShapePath.RoundJoin
            startX: 8.6; startY: 5.2
            PathLine { x: 18.8; y: 12 }
            PathLine { x: 8.6; y: 18.8 }
            PathLine { x: 8.6; y: 5.2 }
        }
    }

    // ── pause ───────────────────────────────────────────────────────────────
    Item {
        width: 24; height: 24
        visible: root.kind === "pause"
        Rectangle { x: 7.4; y: 5.5; width: 3.4; height: 13; radius: 1.4; color: root.color }
        Rectangle { x: 13.2; y: 5.5; width: 3.4; height: 13; radius: 1.4; color: root.color }
    }

    // ── précédent ───────────────────────────────────────────────────────────
    Item {
        width: 24; height: 24
        visible: root.kind === "prev"
        Rectangle { x: 5.6; y: 5.5; width: 2.5; height: 13; radius: 1.2; color: root.color }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 0; strokeColor: "transparent"
                fillColor: root.color
                joinStyle: ShapePath.RoundJoin
                startX: 18.6; startY: 5.4
                PathLine { x: 9.8; y: 12 }
                PathLine { x: 18.6; y: 18.6 }
                PathLine { x: 18.6; y: 5.4 }
            }
        }
    }

    // ── suivant ─────────────────────────────────────────────────────────────
    Item {
        width: 24; height: 24
        visible: root.kind === "next"
        Rectangle { x: 15.9; y: 5.5; width: 2.5; height: 13; radius: 1.2; color: root.color }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 0; strokeColor: "transparent"
                fillColor: root.color
                joinStyle: ShapePath.RoundJoin
                startX: 5.4; startY: 5.4
                PathLine { x: 14.2; y: 12 }
                PathLine { x: 5.4; y: 18.6 }
                PathLine { x: 5.4; y: 5.4 }
            }
        }
    }
}
