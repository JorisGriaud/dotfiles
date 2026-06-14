pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Régime du premier ventilateur trouvé dans hwmon (RPM).
 * `available` reste faux si la machine n'expose aucun capteur.
 */
Singleton {
    id: root

    property string path: ""
    property int rpm: 0
    readonly property bool available: path !== ""

    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/hwmon/hwmon*/fan1_input 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: root.path = this.text.trim()
        }
    }

    FileView {
        id: fanFile
        path: root.path
        onLoaded: {
            const v = parseInt(text())
            if (!isNaN(v))
                root.rpm = v
        }
    }

    Timer {
        interval: 2500
        repeat: true
        running: root.available
        onTriggered: fanFile.reload()
    }
}
