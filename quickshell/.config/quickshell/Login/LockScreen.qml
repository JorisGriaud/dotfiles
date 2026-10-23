import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

/**
 * Écran de verrouillage (ext-session-lock), même visuel que le greeter.
 *
 *   qs ipc call lock lock        — verrouiller
 *   bind : hl.dsp.global("island:lock")
 *
 * `qs ipc call lock preview` ouvre le même écran dans une fenêtre normale
 * (sans verrouiller) : pratique pour tester sans risque. Échap la ferme.
 */
Scope {
    id: root

    function lockNow(): void {
        controller.reset()
        sessionLock.locked = true
    }

    LockController {
        id: controller
        onUnlocked: {
            sessionLock.locked = false
            previewLoader.active = false
        }
        onEscapePressed: previewLoader.active = false
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            id: lockSurface
            color: "black"

            LoginSurface {
                anchors.fill: parent
                ctl: controller
                screenName: lockSurface.screen?.name ?? ""
            }
        }
    }

    // ── aperçu sans verrouillage ────────────────────────────────────────────
    LazyLoader {
        id: previewLoader
        active: false

        PanelWindow {
            id: preview
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "black"
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-lock-preview"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            LoginSurface {
                anchors.fill: parent
                ctl: controller
                screenName: preview.screen?.name ?? ""
            }
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void { root.lockNow() }
        function preview(): void { controller.reset(); previewLoader.active = true }
        function isLocked(): bool { return sessionLock.locked }
    }

    GlobalShortcut {
        appid: "island"
        name: "lock"
        description: "Verrouille la session"
        onPressed: root.lockNow()
    }
}
