import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.Config
import qs.Core
import qs.Services

/**
 * L'îlot morphing — une instance par écran (Variants dans shell.qml).
 *
 * La fenêtre layer-shell est une bande transparente en haut de l'écran ;
 * seule la pilule (et son ombre) est dessinée, et `mask` restreint les
 * entrées souris à la pilule : tout le reste laisse passer les clics.
 *
 * La taille de la pilule est pilotée par deux CriticalSpring qui ciblent
 * les dimensions implicites de la vue active : changer de vue = morphing.
 */
PanelWindow {
    id: win

    property var modelData
    screen: modelData

    // les affichages dynamiques (OSD, notifications, lanceur, polkit)
    // n'apparaissent que sur l'écran qui a le focus
    // (comparaison par nom : les wrappers HyprlandMonitor n'ont pas
    //  d'identité stable entre monitorFor() et focusedMonitor)
    readonly property bool isFocused:
        Hyprland.focusedMonitor !== null
        && Hyprland.focusedMonitor.name === win.screen.name

    // moniteur Hyprland de cet écran + présence d'une fenêtre en plein écran
    readonly property var hyprMonitor:
        Hyprland.monitors.values.find(m => m.name === win.screen.name) ?? null
    readonly property bool monitorFullscreen:
        hyprMonitor?.activeWorkspace?.hasFullscreen ?? false

    // ── épinglage et survol (locaux à cet écran) ────────────────────────────
    property bool pinned: false
    property bool expandedHold: false
    // pas d'expansion au survol tant qu'une fenêtre est en plein écran sur cet
    // écran (sinon l'îlot resurgit au passage de la souris en haut).
    // Le survol ne déclenche l'expansion que depuis repos/étendue : survoler
    // une NOTIFICATION ne doit pas la remplacer par la vue étendue — il fige
    // juste son chrono pour laisser le temps de lire (clic = ouvrir,
    // molette = fermer).
    readonly property bool wantExpanded:
        !monitorFullscreen
        && (pinned || (hoverZone.hovered && (view === "rest" || view === "expanded")))

    onWantExpandedChanged: {
        if (wantExpanded) {
            expandedHold = true
            collapseTimer.stop()
        } else {
            collapseTimer.restart()   // grâce anti-scintillement
        }
    }

    Timer {
        id: collapseTimer
        interval: Settings.hoverCloseDelay
        onTriggered: win.expandedHold = false
    }

    // ── sélection de la vue ─────────────────────────────────────────────────
    readonly property string view: {
        const g = IslandState.globalView
        if (g !== "" && isFocused) {
            // notification reçue alors qu'on était DÉJÀ en vue étendue
            // (survol antérieur ou épinglage) : elle s'affiche en ligne au
            // bas de la vue étendue plutôt que de la remplacer
            if (g === "notification" && expandedHold)
                return "expanded"
            return g
        }
        return expandedHold ? "expanded" : "rest"
    }

    readonly property Item currentItem: {
        switch (view) {
        case "expanded": return expandedV
        case "osd": return osdV
        case "notification": return notifV
        case "launcher": return launcherV
        case "control": return controlV
        case "calendar": return calendarV
        case "power": return powerV
        case "polkit": return polkitV
        default: return restV
        }
    }

    // en plein écran on masque la barre passive (repos/survol) : un changement
    // d'état média — barres d'égaliseur, etc. — ne doit pas la faire resurgir
    // par-dessus une vidéo. OSD, notifications et panneaux restent affichés.
    readonly property bool hiddenForFullscreen:
        monitorFullscreen && (view === "rest" || view === "expanded")

    // ── fenêtre ─────────────────────────────────────────────────────────────
    // bande en haut de l'écran au repos ; PLEIN ÉCRAN quand un panneau est
    // ouvert, pour que tout clic hors de la pilule le referme (modal).
    anchors {
        top: true
        left: true
        right: true
        bottom: win.panelOpen
    }
    // doit contenir le pire cas du centre de contrôle (~740 px de contenu)
    implicitHeight: 820
    color: "transparent"
    // l'îlot ne réserve JAMAIS d'espace lui-même : c'est la fenêtre « spacer »
    // dédiée (plus bas) qui le fait. Il peut donc passer en plein écran pour
    // capter les clics de fermeture SANS jamais réagencer les fenêtres.
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "morphing-island"
    WlrLayershell.keyboardFocus: {
        if (!isFocused)
            return WlrKeyboardFocus.None
        switch (view) {
        case "launcher":   // saisie
        case "polkit":     // mot de passe
        case "power":      // navigation flèches
        case "control":    // Échap toujours actif : un clic dans le vide
        case "calendar":   // ne doit jamais voler le focus du panneau
            return WlrKeyboardFocus.Exclusive
        default:
            return WlrKeyboardFocus.None
        }
    }

    // panneau modal ouvert sur cet écran ?
    // Polkit est volontairement exclu : l'authentification ne se ferme
    // qu'explicitement (Échap ou validation).
    readonly property bool panelOpen:
        isFocused && (view === "launcher" || view === "control"
                   || view === "calendar" || view === "power")

    // masque d'entrée :
    //   plein écran (panneau ouvert) → TOUTE la fenêtre capte les clics
    //   barre cachée (plein écran)   → rien (les clics passent à la vidéo)
    //   sinon                        → seule la pilule
    Region {
        id: pillRegion
        item: pill
    }
    Region { id: emptyRegion }   // aucune entrée : tout passe au travers
    mask: win.hiddenForFullscreen ? emptyRegion
        : win.panelOpen ? null
        : pillRegion

    // attrape-clics MODAL : derrière la pilule (déclaré AVANT elle, donc
    // dessous) — il ne reçoit que les clics HORS pilule et referme le panneau.
    // Polkit est exclu : l'authentification ne se ferme qu'explicitement.
    MouseArea {
        anchors.fill: parent
        enabled: win.panelOpen
        visible: win.panelOpen
        onClicked: IslandState.closePanel()
    }

    // réservation d'espace CONSTANTE : fenêtre dédiée, jamais redimensionnée.
    // C'est elle — et non l'îlot — qui pousse les fenêtres ; ouvrir un panneau
    // (qui ne fait grandir que l'îlot, en Ignore) ne réagence donc rien.
    //
    // Réservation calculée pour que le BORD VISIBLE de la fenêtre du dessous
    // tombe exactement à `restHeight + 2*topMargin` du haut de l'écran (=
    // floatBand). On retranche gaps_out car Hyprland l'ajoute lui-même entre
    // la zone réservée et le bord de la fenêtre :
    //   bord visible = reservedHeight + gaps_out = restHeight + 2*topMargin.
    readonly property int reservedHeight:
        Settings.restHeight + 2 * Settings.topMargin - Settings.gapsOut

    PanelWindow {
        visible: Settings.reserveSpace
        screen: win.screen
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: win.reservedHeight
        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: win.reservedHeight
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "morphing-island-spacer"
        mask: Region {}   // ne capte aucun clic
    }

    // ── ressorts de morphing ────────────────────────────────────────────────
    CriticalSpring {
        id: wSpring
        speed: Theme.springFast
        target: win.currentItem.implicitWidth
    }

    CriticalSpring {
        id: hSpring
        speed: Theme.springFast
        // la pilule épouse exactement la hauteur du contenu : le contenu de
        // chaque vue est centré, sans vide.
        target: win.currentItem.implicitHeight
    }

    // ── position verticale de la pilule ─────────────────────────────────────
    // bande libre au-dessus des fenêtres (écran → fenêtre du dessous). L'écart
    // sous la pilule vaut le gaps_out d'Hyprland ≈ topMargin, donc la bande
    // vaut restHeight + 2*topMargin.
    readonly property int floatBand: Settings.restHeight + 2 * Settings.topMargin

    // les vues qui TIENNENT dans la bande sont CENTRÉES verticalement (mêmes
    // marges haut/bas → elles grandissent symétriquement au survol) ; les
    // panneaux plus hauts restent ancrés en haut (ils flottent par-dessus).
    readonly property int pillY: win.currentItem.implicitHeight <= floatBand
        ? Math.round((floatBand - win.currentItem.implicitHeight) / 2)
        : Settings.topMargin

    CriticalSpring {
        id: ySpring
        speed: Theme.springFast
        target: win.pillY
    }

    Component.onCompleted: {
        wSpring.snap()
        hSpring.snap()
        ySpring.snap()
    }

    // ── ombre subtile ───────────────────────────────────────────────────────
    RectangularShadow {
        anchors.fill: pill
        radius: pill.radius
        blur: Theme.shadowBlur
        spread: 0
        color: Theme.shadowColor
        offset: Qt.vector2d(0, Theme.shadowYOffset)
        visible: !win.hiddenForFullscreen
    }

    // ── la pilule ───────────────────────────────────────────────────────────
    ClippingRectangle {
        id: pill
        visible: !win.hiddenForFullscreen
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(ySpring.value)
        width: Math.max(4, Math.round(wSpring.value))
        height: Math.max(4, Math.round(hSpring.value))
        radius: Math.min(height / 2, 28)
        color: Theme.islandBg
        border.color: Theme.islandBorder
        border.width: 1

        HoverHandler {
            id: hoverZone
        }

        // clic "dans le vide" : épingle/désépingle, ou agit sur l'affichage
        // courant. Les boutons (IslandButton, MouseArea des vues) consomment
        // leurs clics avant d'arriver ici, sans toucher à l'épinglage.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: mouseEvent => {
                switch (win.view) {
                case "rest":
                case "expanded":
                    if (mouseEvent.button === Qt.LeftButton)
                        win.pinned = !win.pinned
                    break
                case "notification":
                    // clic = ouvrir l'app/la page, molette = fermer
                    if (mouseEvent.button === Qt.MiddleButton)
                        Notifs.dismissCurrent()
                    else
                        Notifs.activateCurrent()
                    break
                case "osd":
                    IslandState.hideOsd()
                    break
                // calendrier / centre de contrôle / power : un clic dans le
                // vide ne ferme rien et ne perd pas le focus (Échap ou la
                // flèche retour pour sortir)
                }
            }
        }

        RestView {
            id: restV
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            active: win.view === "rest"
        }

        ExpandedView {
            id: expandedV
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            active: win.view === "expanded"
        }

        OsdView {
            id: osdV
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            active: win.view === "osd"
        }

        NotificationView {
            id: notifV
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            active: win.view === "notification"
        }

        LauncherView {
            id: launcherV
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            active: win.view === "launcher"
        }

        ControlCenterView {
            id: controlV
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            active: win.view === "control"
        }

        CalendarView {
            id: calendarV
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            active: win.view === "calendar"
        }

        PowerView {
            id: powerV
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            active: win.view === "power"
        }

        PolkitView {
            id: polkitV
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            active: win.view === "polkit"
        }
    }

    // survoler la notification met son chronomètre en pause.
    // `isFocused` est intégré au calcul : un îlot non focalisé garde
    // notifHovered constamment faux et n'écrit donc jamais. L'écriture est
    // inconditionnelle pour que la transition vrai→faux se propage TOUJOURS
    // (sinon hoverPaused resterait bloqué à true si le focus quitte l'écran
    //  en plein survol — et l'auto-dismiss serait gelé pour toutes les notifs).
    readonly property bool notifHovered: isFocused && hoverZone.hovered
        && Notifs.current !== null
        && (view === "notification" || view === "expanded")
    onNotifHoveredChanged: Notifs.hoverPaused = notifHovered

    // survol de l'OSD : fige son chrono (le temps d'attraper le rond)
    readonly property bool osdHover: isFocused && hoverZone.hovered && view === "osd"
    onOsdHoverChanged: IslandState.osdHovered = osdHover

    // filets de sécurité : perte de focus ou destruction (débranchement
    // d'écran) en plein survol ne doivent jamais laisser un verrou coincé
    onIsFocusedChanged: {
        if (!isFocused) {
            Notifs.hoverPaused = false
            IslandState.osdHovered = false
        }
    }
    Component.onDestruction: {
        if (isFocused) {
            Notifs.hoverPaused = false
            IslandState.osdHovered = false
        }
    }
}
