import QtQuick

/**
 * Pavage de fenêtres — rechargement d'Hyprland.
 */
Icon {
    id: root

    Rectangle {
        x: 2.8; y: 4.2; width: 8.4; height: 15.6
        radius: 2.2
        color: "transparent"
        border.color: root.color
        border.width: root.strokeWidth
    }
    Rectangle {
        x: 12.8; y: 4.2; width: 8.4; height: 6.8
        radius: 2.2
        color: "transparent"
        border.color: root.color
        border.width: root.strokeWidth
    }
    Rectangle {
        x: 12.8; y: 13; width: 8.4; height: 6.8
        radius: 2.2
        color: "transparent"
        border.color: root.color
        border.width: root.strokeWidth
    }
}
