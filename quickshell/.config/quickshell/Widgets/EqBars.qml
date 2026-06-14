import QtQuick
import qs.Config

/**
 * Petites barres d'égaliseur animées (visibles quand la musique joue).
 * Mouvement organique : somme de deux sinusoïdes déphasées par barre.
 */
Item {
    id: root

    property int count: 4
    property bool playing: false
    property color color: Theme.accent

    readonly property real barWidth: 2.6
    readonly property real gap: 2.2

    implicitWidth: count * (barWidth + gap) - gap
    implicitHeight: 14

    FrameAnimation {
        id: anim
        running: root.playing && root.visible
    }

    Repeater {
        model: root.count
        delegate: Rectangle {
            required property int index

            readonly property real phase: index * 1.7
            readonly property real f1: 6.4 + index * 1.18
            readonly property real f2: 2.9 + index * 0.63

            x: index * (root.barWidth + root.gap)
            anchors.verticalCenter: parent.verticalCenter
            width: root.barWidth
            radius: root.barWidth / 2
            color: root.color

            height: {
                if (!root.playing)
                    return 3
                const t = anim.elapsedTime
                const v = Math.abs(Math.sin(t * f1 + phase) * 0.65
                                 + Math.sin(t * f2 + phase * 2.3) * 0.35)
                return 3.5 + v * (root.implicitHeight - 3.5)
            }
            Behavior on height {
                enabled: !root.playing   // retombée douce à la pause
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
        }
    }
}
