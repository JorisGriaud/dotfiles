import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Services
import qs.Island

/**
 * Morphing Island — point d'entrée.
 *
 * Lancement (sans toucher à ~/.config/quickshell) :
 *   qs -p ~/Documents/quickshell-ytb
 *
 * Voir README.md pour les binds Hyprland (lanceur, luminosité…).
 */
ShellRoot {
    // un îlot par écran ; les affichages dynamiques ne sortent
    // que sur l'écran focalisé (géré dans Island.qml)
    Variants {
        model: Quickshell.screens
        Island {}
    }

    // raccourci natif Hyprland : bind = SUPER, SPACE, global, island:launcher
    GlobalShortcut {
        appid: "island"
        name: "launcher"
        description: "Ouvre le lanceur de l'îlot"
        onPressed: IslandState.toggleLauncher()
    }

    GlobalShortcut {
        appid: "island"
        name: "peace"
        description: "Bascule le mode Ne pas déranger"
        onPressed: Notifs.togglePeace()
    }

    // bind = SUPER, ESCAPE, global, island:power
    GlobalShortcut {
        appid: "island"
        name: "power"
        description: "Menu éteindre / redémarrer / déconnexion"
        onPressed: IslandState.togglePanel("power")
    }

    // pilotage en ligne de commande :
    //   qs -p ~/Documents/quickshell-ytb ipc call island toggleLauncher
    IpcHandler {
        target: "island"

        function toggleLauncher(): void { IslandState.toggleLauncher() }
        function toggleControlCenter(): void { IslandState.togglePanel("control") }
        function toggleCalendar(): void { IslandState.togglePanel("calendar") }
        function togglePower(): void { IslandState.togglePanel("power") }
        function togglePeace(): void { Notifs.togglePeace() }
        // rechargement dur : recrée les fenêtres (utile si une propriété
        // de surface — couche, namespace — a changé)
        function reload(): void { Quickshell.reload(true) }
        // ouvre directement une page du centre de contrôle :
        //   qs -p … ipc call island ccPage audio|network|bluetooth
        function ccPage(p: string): void { IslandState.openCcPage(p) }
        function brightnessUp(): void { Brightness.adjust(5) }
        function brightnessDown(): void { Brightness.adjust(-5) }
        function volumeUp(): void { Audio.adjust(0.05) }
        function volumeDown(): void { Audio.adjust(-0.05) }
        function muteToggle(): void { Audio.toggleMute() }
    }
}
