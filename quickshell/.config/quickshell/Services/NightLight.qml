pragma Singleton
import QtQuick
import Quickshell

/**
 * Filtre nuit via hyprsunset (le daemon doit tourner :
 * `exec-once = hyprsunset` dans la config Hyprland).
 */
Singleton {
    id: root

    property bool active: false
    property int temperature: 3800   // kelvins en mode nuit

    function toggle() {
        active = !active
        Quickshell.execDetached(["sh", "-c",
            active ? `hyprctl hyprsunset temperature ${temperature}`
                   : "hyprctl hyprsunset identity"])
    }
}
