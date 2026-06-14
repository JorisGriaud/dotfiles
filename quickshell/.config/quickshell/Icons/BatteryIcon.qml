import QtQuick
import qs.Config
import qs.Core

/**
 * Batterie style iOS : pourcentage à l'intérieur, niveau en remplissage,
 * éclair vert qui surgit (ressort) au branchement.
 * Composant autonome (pas de mise à l'échelle 24×24 : le texte doit rester net).
 */
Item {
    id: root

    property real level: 1            // 0..1
    property bool charging: false
    property real size: 14            // hauteur du corps
    property color color: Theme.fg

    implicitWidth: body.width + 3.5
    implicitHeight: size

    CriticalSpring {
        id: fillSpring
        speed: Theme.springSoft
        target: Math.max(0, Math.min(1, root.level))
    }

    // apparition de l'éclair au branchement
    CriticalSpring {
        id: boltSpring
        speed: Theme.springNormal
        target: root.charging ? 1 : 0
    }

    Rectangle {
        id: body
        width: root.size * 2.15
        height: root.size
        radius: root.size * 0.30
        color: "transparent"
        border.color: Qt.alpha(root.color, 0.5)
        border.width: 1.2
    }

    // borne (le téton à droite)
    Rectangle {
        anchors.left: body.right
        anchors.leftMargin: 1.2
        anchors.verticalCenter: body.verticalCenter
        width: 2.2
        height: root.size * 0.42
        radius: 1.1
        color: Qt.alpha(root.color, 0.5)
    }

    // remplissage = niveau de charge
    Rectangle {
        x: 2
        anchors.verticalCenter: body.verticalCenter
        height: root.size - 4
        width: Math.max(0, (body.width - 4) * fillSpring.value)
        radius: Math.min(root.size * 0.18, width / 2)
        color: root.charging ? Theme.success
             : root.level <= 0.20 ? Theme.critical
             : Qt.alpha(root.color, 0.38)
        Behavior on color { ColorAnimation { duration: Theme.fadeDuration } }
    }

    Row {
        anchors.centerIn: body
        spacing: 0

        BoltIcon {
            anchors.verticalCenter: parent.verticalCenter
            size: root.size * 0.78
            color: Theme.fg
            outlineColor: Theme.islandBg
            visible: boltSpring.value > 0.02
            scale: boltSpring.value
            // origine à gauche : le scale (étendue [0, size·v]) coïncide alors
            // exactement avec le slot width, sans dérive ni chevauchement du %
            transformOrigin: Item.Left
            width: size * boltSpring.value   // libère la place quand absent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.level * 100)
            color: Theme.fg
            style: Text.Outline
            styleColor: Theme.islandBg
            font.family: Theme.fontFamily
            font.pixelSize: root.size * 0.66
            font.weight: Theme.fontWeightStrong
        }
    }
}
