pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

/**
 * État réseau via le module natif Quickshell.Networking (NetworkManager).
 * `strength` ∈ [0,1] alimente la jauge de l'icône Wi-Fi.
 * L'IP privée est lue via `ip -4 addr` (croisée avec l'interface active).
 */
Singleton {
    id: root

    readonly property var wifiDevice:
        Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

    readonly property var wiredDevice:
        Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null

    readonly property var activeWifi:
        wifiDevice ? (wifiDevice.networks.values.find(n => n.connected) ?? null) : null

    readonly property bool wiredConnected: wiredDevice !== null
    readonly property bool wifiConnected: wifiDevice !== null && wifiDevice.connected
    readonly property bool connected: wifiConnected || wiredConnected

    // nom de l'interface active (ex. enp5s0 / wlan0)
    readonly property string ifaceName:
        wiredConnected ? wiredDevice.name : (wifiDevice?.name ?? "")

    readonly property real strength: {
        if (!activeWifi)
            return 0
        const s = activeWifi.signalStrength
        return Math.max(0, Math.min(1, s > 1 ? s / 100 : s))
    }

    // ── IP privée de l'interface active ─────────────────────────────────────
    property var ipByIface: ({})
    readonly property string ipAddress: ipByIface[ifaceName] ?? ""

    // une demande arrivée pendant qu'un `ip addr` tourne déjà serait perdue
    // (running=true sur un process actif est un no-op) : on la met en attente
    property bool ipRefreshPending: false

    function refreshIp() {
        if (ipProc.running) {
            ipRefreshPending = true
            return
        }
        ipProc.running = true
    }

    Process {
        id: ipProc
        running: true
        command: ["sh", "-c", "ip -4 -o addr show scope global | awk '{print $2, $4}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {}
                for (const line of this.text.split("\n")) {
                    const parts = line.trim().split(" ")
                    if (parts.length === 2)
                        map[parts[0]] = parts[1].split("/")[0]
                }
                root.ipByIface = map
                if (root.ipRefreshPending) {
                    root.ipRefreshPending = false
                    root.refreshIp()
                }
            }
        }
    }

    Timer {
        interval: 15000
        repeat: true
        running: true
        onTriggered: root.refreshIp()
    }

    // re-lire dès qu'une connexion change (DHCP…)
    onConnectedChanged: refreshIp()
    onIfaceNameChanged: refreshIp()
}
