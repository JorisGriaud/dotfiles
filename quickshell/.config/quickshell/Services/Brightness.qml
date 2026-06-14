pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Luminosité du rétroéclairage (sysfs + brightnessctl pour l'écriture).
 *
 * Les écritures sysfs ne génèrent pas d'événement inotify fiable : on
 * surveille le fichier ET on le recharge à intervalle court. Pour un OSD
 * instantané, bindez vos touches sur `qs ... ipc call island brightnessUp/Down`.
 */
Singleton {
    id: root

    property string device: ""
    property int max: 0
    property int raw: -1
    readonly property real level: max > 0 && raw >= 0 ? raw / max : 0
    readonly property bool available: device !== "" && max > 0

    // évite un OSD parasite au premier chargement
    property bool armed: false

    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: root.device = this.text.trim()
        }
    }

    FileView {
        path: root.device !== "" ? `/sys/class/backlight/${root.device}/max_brightness` : ""
        onLoaded: root.max = parseInt(text()) || 0
    }

    FileView {
        id: curFile
        path: root.device !== "" ? `/sys/class/backlight/${root.device}/brightness` : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const v = parseInt(text())
            if (isNaN(v))
                return
            // juste après une écriture optimiste, sysfs peut encore contenir
            // l'ancienne valeur (latence brightnessctl) : ignorer ce reflux
            if (Date.now() - root.lastWriteMs < 400 && v !== root.raw)
                return
            root.raw = v
        }
    }

    // filet de sécurité : sysfs ne notifie pas toujours
    Timer {
        interval: 1000
        repeat: true
        running: root.available
        onTriggered: curFile.reload()
    }

    Timer {
        interval: 2000
        running: true
        onTriggered: root.armed = true
    }

    onRawChanged: {
        if (armed && available)
            IslandState.showOsd("brightness")
    }

    // horodatage de la dernière écriture optimiste (anti-reflux du poll)
    property real lastWriteMs: 0

    function set(pct) {
        if (!available)
            return
        const clamped = Math.max(0.01, Math.min(1, pct))
        // l'écriture finale exacte remplace toute écriture throttlée en attente
        throttle.stop()
        pendingLevel = -1
        Quickshell.execDetached(["brightnessctl", "-c", "backlight", "set",
                                 Math.round(clamped * 100) + "%"])
        // retour visuel immédiat sans attendre la relecture sysfs
        root.raw = Math.round(clamped * max)
        root.lastWriteMs = Date.now()
        IslandState.showOsd("brightness")
    }

    function adjust(deltaPct) {
        set(level + deltaPct / 100)
    }

    // version "drag" : retour visuel immédiat, mais au plus un appel
    // brightnessctl tous les ~100 ms (un process par appel sinon)
    property real pendingLevel: -1

    function setLive(pct) {
        if (!available)
            return
        pendingLevel = Math.max(0.01, Math.min(1, pct))
        root.raw = Math.round(pendingLevel * max)
        root.lastWriteMs = Date.now()
        if (!throttle.running)
            throttle.start()
    }

    Timer {
        id: throttle
        interval: 100
        onTriggered: {
            if (root.pendingLevel >= 0) {
                Quickshell.execDetached(["brightnessctl", "-c", "backlight", "set",
                                         Math.round(root.pendingLevel * 100) + "%"])
                root.pendingLevel = -1
            }
        }
    }
}
