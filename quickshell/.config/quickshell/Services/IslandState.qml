pragma Singleton
import QtQuick
import Quickshell
import qs.Config

/**
 * Machine à états globale de l'îlot.
 *
 * `panel` = panneau ouvert par l'utilisateur sur l'écran focalisé :
 *   "" | "launcher" | "control" | "calendar" | "power"
 *
 * `globalView` désigne la vue prioritaire ("" = rien de global ; chaque îlot
 * retombe alors sur repos/survol).
 * Priorités : polkit > panneau utilisateur > notification > OSD.
 */
Singleton {
    id: root

    property string panel: ""

    // page du centre de contrôle — GLOBALE : les deux instances (une par
    // écran) lisent/écrivent le même état, donc un changement d'écran
    // focalisé ne coupe pas un scan en cours et ne perd pas la page
    property string ccPage: "main"

    onPanelChanged: {
        if (panel !== "control")
            ccPage = "main"
    }

    // ouverture directe d'une page (IPC `ccPage <p>`)
    function openCcPage(p) {
        if (!["main", "network", "audio", "bluetooth"].includes(p))
            p = "main"
        panel = "control"
        hideOsd()   // sinon un OSD masqué referait surface à la fermeture
        ccPage = p
    }
    property string osdKind: "volume"   // "volume" | "brightness"
    property bool osdVisible: false
    property bool osdHovered: false     // survol de l'OSD = chrono en pause (drag du rond)

    readonly property bool launcherOpen: panel === "launcher"

    readonly property string globalView:
        PolkitService.active ? "polkit"
      : panel !== "" ? panel
      : Notifs.current !== null ? "notification"
      : osdVisible ? "osd"
      : ""

    function showOsd(kind) {
        // l'OSD ne doit jamais interrompre un panneau, une authentification
        // ou une notification — sinon il referait surface (flash) une fois la
        // notification fermée, le timer ayant continué à tourner derrière elle.
        if (panel !== "" || PolkitService.active || Notifs.current !== null)
            return
        osdKind = kind
        osdVisible = true
        if (!osdHovered)
            osdTimer.restart()
    }

    function hideOsd() {
        osdTimer.stop()
        osdVisible = false
    }

    // ── panneaux ────────────────────────────────────────────────────────────
    function togglePanel(p) {
        panel = (panel === p) ? "" : p
        if (panel !== "")
            hideOsd()
    }

    function closePanel() {
        panel = ""
    }

    function toggleLauncher() { togglePanel("launcher") }
    function closeLauncher() { if (panel === "launcher") panel = "" }

    // survol pendant l'OSD : on fige le chrono (le temps d'attraper le rond),
    // il repart à zéro quand la souris s'en va
    onOsdHoveredChanged: {
        if (osdHovered)
            osdTimer.stop()
        else if (osdVisible)
            osdTimer.restart()
    }

    Timer {
        id: osdTimer
        interval: Settings.osdTimeout
        onTriggered: root.osdVisible = false
    }
}
