import QtQuick

/**
 * Écran sur pied — portails XDG (partage d'écran, sélecteurs de fichiers).
 */
Icon {
    id: root

    Rectangle {
        x: 2.6; y: 4; width: 18.8; height: 13.2
        radius: 2.6
        color: "transparent"
        border.color: root.color
        border.width: root.strokeWidth
    }

    // pied
    Rectangle {
        x: 12 - root.strokeWidth / 2; y: 17.2
        width: root.strokeWidth; height: 2.6
        color: root.color
    }
    Rectangle {
        x: 7.6; y: 19.8 - root.strokeWidth / 2
        width: 8.8; height: root.strokeWidth
        radius: root.strokeWidth / 2
        color: root.color
    }
}
