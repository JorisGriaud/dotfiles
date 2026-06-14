pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Polkit

/**
 * Agent d'authentification Polkit intégré à l'îlot.
 * NB : un seul agent peut être enregistré par session — désactivez
 * l'agent graphique existant (polkit-gnome, hyprpolkitagent…) pour
 * que `registered` passe à vrai.
 */
Singleton {
    id: root

    readonly property var flow: agent.flow
    readonly property bool active: flow !== null && !flow.isCompleted
    readonly property bool registered: agent.isRegistered

    PolkitAgent {
        id: agent
    }

    function submit(password) {
        if (flow)
            flow.submit(password)
    }

    function cancel() {
        if (flow)
            flow.cancelAuthenticationRequest()
    }
}
