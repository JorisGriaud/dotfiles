import QtQuick
import qs.Config

/**
 * Ventilateur 3 pales — tourne à une vitesse proportionnelle au régime (RPM).
 */
Icon {
    id: root

    property int rpm: 0
    readonly property bool spinning: rpm > 0

    Item {
        id: rotor
        width: 24
        height: 24

        Repeater {
            model: 3
            delegate: Rectangle {
                required property int index
                width: 4.6
                height: 7.6
                radius: 2.3
                color: root.color
                x: 12 - width / 2
                y: 1.8
                transform: Rotation {
                    origin.x: 2.3
                    origin.y: 10.2   // centre du rotor vu depuis la pale
                    angle: index * 120
                }
            }
        }

        Rectangle {
            x: 12 - 3
            y: 12 - 3
            width: 6
            height: 6
            radius: 3
            color: root.color
            border.color: Theme.islandBg
            border.width: 1
        }

        RotationAnimation on rotation {
            running: root.spinning && root.visible
            loops: Animation.Infinite
            from: 0
            to: 360
            // plus le régime est haut, plus ça tourne vite (bornes visuelles)
            duration: Math.max(450, 2600 - root.rpm * 0.6)
        }

        // à l'arrêt (RPM = 0), ramener l'angle de repos sur 0 : le from:0 du
        // redémarrage coïncide alors avec la position actuelle, pas de saut.
        onVisibleChanged: if (!visible) rotation = 0
    }

    onSpinningChanged: if (!spinning) rotor.rotation = 0
}
