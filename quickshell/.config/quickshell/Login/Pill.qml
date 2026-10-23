import QtQuick
import QtQuick.Effects
import qs.Config

/**
 * Pilule au style de l'îlot : fond islandBg, liseré, ombre douce.
 */
Rectangle {
    radius: height / 2
    color: Theme.islandBg
    border.width: 1
    border.color: Theme.islandBorder

    Behavior on border.color { ColorAnimation { duration: Theme.fadeDuration } }

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.shadowColor
        shadowBlur: 1.0
        blurMax: Theme.shadowBlur
        shadowVerticalOffset: Theme.shadowYOffset
    }
}
