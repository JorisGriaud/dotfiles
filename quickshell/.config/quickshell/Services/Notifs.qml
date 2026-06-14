pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.Config

/**
 * Serveur de notifications.
 *  - popup : une à la fois dans l'îlot, file d'attente derrière
 *  - survol = chronomètre en pause (`hoverPaused`, piloté par l'îlot)
 *  - critiques : délai allongé + accent rouge
 *  - mode "Peace" : aucune popup, mais la notif reste dans l'historique
 *
 * Les notifications restent VIVANTES (tracked) tant qu'elles sont dans
 * l'historique : on peut donc rejouer leur action par défaut (« ouvrir »)
 * depuis le centre de contrôle. Le passage du chronomètre ne les FERME pas,
 * il ne fait que retirer la popup ; elles ne sont fermées qu'explicitement
 * (clic molette / croix / « Tout effacer »), par leur app, ou au-delà du cap.
 */
Singleton {
    id: root

    property bool peace: false
    property bool hoverPaused: false

    property var current: null    // Notification affichée en popup
    property var queue: []        // notifications en attente de popup
    // historique : { notif, time, icon, appName, summary, body, critical, desktopEntry }
    property var history: []

    readonly property int historyCap: 50

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true
            // un seul gestionnaire de fermeture par notif : purge file +
            // historique, et fait avancer la popup si c'était la courante
            n.closed.connect(() => root.onNotifClosed(n))
            // mise à jour sur place (replaces_id) : rafraîchir l'instantané
            // d'historique, sinon il afficherait l'ancien texte/icône
            const refresh = () => root.refreshEntry(n)
            n.summaryChanged.connect(refresh)
            n.bodyChanged.connect(refresh)
            n.appIconChanged.connect(refresh)
            n.imageChanged.connect(refresh)
            n.urgencyChanged.connect(refresh)
            root.remember(n)

            if (root.peace)
                return   // pas de popup, mais gardée + action rejouable

            if (root.current === null)
                root.current = n
            else {
                root.queue.push(n)
                root.queueChanged()
            }
        }
    }

    // ── chronomètre à échéance : vraie pause au survol ──────────────────────
    // (un Timer QML repart toujours de zéro ; on conserve donc nous-mêmes
    //  le temps restant pour le reprendre là où il s'était arrêté)
    property real remainingMs: 0
    property real deadlineMs: 0

    // la popup n'est RÉELLEMENT visible que si rien de plus prioritaire
    // (polkit, panneau) ne la masque. Le chronomètre est gelé tant qu'elle
    // est cachée, sinon une notif reçue derrière un panneau serait « avalée »
    // sans avoir été vue.
    readonly property bool popupShown: IslandState.globalView === "notification"

    function baseInterval() {
        return (current && current.urgency === NotificationUrgency.Critical)
            ? Settings.notifCriticalTimeout
            : Settings.notifTimeout
    }

    function armTimer(ms) {
        deadlineMs = Date.now() + ms
        hideTimer.interval = Math.max(1, ms)
        hideTimer.restart()
    }

    onCurrentChanged: {
        if (current !== null) {
            remainingMs = baseInterval()
            if (!hoverPaused && popupShown)
                armTimer(remainingMs)
            else
                hideTimer.stop()
        } else {
            hideTimer.stop()
        }
    }

    onHoverPausedChanged: {
        if (current === null)
            return
        if (hoverPaused) {
            remainingMs = Math.max(0, deadlineMs - Date.now())
            hideTimer.stop()
        } else if (popupShown) {
            armTimer(remainingMs)
        }
    }

    // panneau/polkit passe devant → on gèle ; il se referme → on reprend
    // (même logique que la pause au survol, temps restant conservé)
    onPopupShownChanged: {
        if (current === null)
            return
        if (!popupShown) {
            remainingMs = Math.max(0, deadlineMs - Date.now())
            hideTimer.stop()
        } else if (!hoverPaused) {
            armTimer(remainingMs)
        }
    }

    Timer {
        id: hideTimer
        repeat: false
        // expiration de la popup : on retire juste l'affichage, la notif
        // reste dans l'historique (et reste rejouable)
        onTriggered: root.promoteNext()
    }

    // ── historique ──────────────────────────────────────────────────────────
    // résout une icône PERSISTANTE : icône du thème d'abord (son fichier
    // survit), sinon l'image fournie par la notification
    function iconFor(n) {
        if (n.appIcon !== "") {
            if (n.appIcon.startsWith("/") || n.appIcon.startsWith("file://"))
                return n.appIcon
            const p = Quickshell.iconPath(n.appIcon, true)
            if (p !== "")
                return p
        }
        return n.image !== "" ? n.image : ""
    }

    function remember(n) {
        root.history.unshift({
            notif: n,
            time: Time.time,
            icon: iconFor(n),
            appName: n.appName,
            summary: n.summary,
            body: n.body,
            critical: n.urgency === NotificationUrgency.Critical,
            desktopEntry: n.desktopEntry,
        })
        // au-delà du cap, on ferme (et libère) les plus anciennes
        while (root.history.length > root.historyCap) {
            const old = root.history.pop()
            if (old.notif)
                old.notif.dismiss()
        }
        root.historyChanged()
    }

    // notif mise à jour sur place : rafraîchir son entrée d'historique
    function refreshEntry(n) {
        for (let i = 0; i < root.history.length; i++) {
            const e = root.history[i]
            if (e.notif === n) {
                e.icon = iconFor(n)
                e.appName = n.appName
                e.summary = n.summary
                e.body = n.body
                e.critical = n.urgency === NotificationUrgency.Critical
                root.historyChanged()
                break
            }
        }
    }

    // ── popup ────────────────────────────────────────────────────────────────
    function promoteNext() {
        root.current = null
        while (root.queue.length > 0) {
            const next = root.queue.shift()
            root.queueChanged()
            if (next) {
                root.current = next
                break
            }
        }
    }

    function invokeDefault(n) {
        if (!n)
            return
        let act = null
        for (let i = 0; i < n.actions.length; i++) {
            if (n.actions[i].identifier === "default") {
                act = n.actions[i]
                break
            }
        }
        if (!act && n.actions.length === 1)
            act = n.actions[0]
        if (act)
            act.invoke()
    }

    // fermeture d'une notif (par son app, par dismiss(), ou au-delà du cap)
    function onNotifClosed(n) {
        const qi = root.queue.indexOf(n)
        if (qi >= 0) {
            root.queue.splice(qi, 1)
            root.queueChanged()
        }
        for (let i = 0; i < root.history.length; i++) {
            if (root.history[i].notif === n) {
                root.history.splice(i, 1)
                root.historyChanged()
                break
            }
        }
        if (root.current === n)
            root.promoteNext()
    }

    // clic gauche sur la popup : ouvre (action par défaut), puis passe à la
    // suivante — la notif reste dans l'historique
    function activateCurrent() {
        const n = root.current
        if (!n)
            return
        invokeDefault(n)
        // si l'action a déjà fermé la notif, onNotifClosed a déjà avancé :
        // ne pas re-promouvoir (sinon on sauterait la suivante)
        if (root.current === n)
            promoteNext()
    }

    // clic molette sur la popup : ferme la notif (et la retire de l'historique)
    function dismissCurrent() {
        if (root.current)
            root.current.dismiss()
    }

    // ── historique : clic = ouvrir, molette / croix = retirer ───────────────
    function activateEntry(entry) {
        if (entry && entry.notif)
            invokeDefault(entry.notif)
    }

    function removeEntry(entry) {
        const i = root.history.indexOf(entry)
        if (i >= 0) {
            root.history.splice(i, 1)
            root.historyChanged()
        }
        if (entry && entry.notif)
            entry.notif.dismiss()
    }

    function clearHistory() {
        const items = root.history.slice()
        root.history = []
        root.historyChanged()
        for (const e of items)
            if (e.notif)
                e.notif.dismiss()
    }

    function togglePeace() {
        root.peace = !root.peace
    }
}
