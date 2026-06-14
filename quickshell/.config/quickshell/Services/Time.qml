pragma Singleton
import QtQuick
import Quickshell

/**
 * Horloge système partagée.
 */
Singleton {
    id: root

    readonly property string time: Qt.formatDateTime(clock.date, "HH:mm")
    readonly property var now: clock.date   // pour le calendrier
    readonly property string longDate: {
        const locale = Qt.locale("fr_FR");
        const d = clock.date.toLocaleDateString(locale, "dddd d MMMM");
        return d.charAt(0).toUpperCase() + d.slice(1)
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
