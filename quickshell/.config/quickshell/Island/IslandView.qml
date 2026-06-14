import QtQuick
import qs.Config

/**
 * Base de toutes les vues de l'îlot : fondu enchaîné quand la vue
 * devient (in)active. Le morphing de taille de la pilule est piloté par
 * les ressorts de Island.qml, qui ciblent implicitWidth/implicitHeight.
 */
Item {
    id: root

    property bool active: false

    width: implicitWidth
    height: implicitHeight

    opacity: active ? 1 : 0
    visible: opacity > 0.004
    Behavior on opacity {
        NumberAnimation { duration: Theme.fadeDuration; easing.type: Easing.OutCubic }
    }
}
