pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.Config

/**
 * Serveur de notifications.
 *  - popup : un GROUPE à la fois (notifications d'une même application
 *    reçues pendant l'affichage), file d'attente derrière
 *  - survol ou réponse en cours = chronomètre en pause (`paused`)
 *  - rafale : délai raccourci quand la file s'allonge
 *  - critiques : restent affichées jusqu'à un clic ou la croix
 *  - Ne pas déranger : pas de popup (sauf critiques), plage horaire
 *    automatique, résumé à la sortie
 *  - historique daté, groupé par jour et par application, enregistré sur
 *    disque et rechargé au redémarrage (en lecture seule : les actions ne
 *    sont plus rejouables, l'application ne connaît plus ces notifications)
 *
 * Les notifications restent VIVANTES (tracked) tant qu'elles sont dans
 * l'historique : on peut rejouer leur action par défaut depuis le centre de
 * contrôle. Le passage du chronomètre ne les FERME pas, il retire seulement
 * la popup ; elles ne sont fermées qu'explicitement (clic molette, croix de
 * l'historique, « Tout effacer »), par leur application, ou au-delà du cap.
 */
Singleton {
    id: root

    // ── état public ─────────────────────────────────────────────────────────
    property bool peace: false
    property int peaceMissed: 0        // notifications reçues pendant ce Ne pas déranger
    property real peaceSinceMs: 0

    property bool hoverPaused: false   // survol de la popup (piloté par l'îlot)
    property bool replying: false      // saisie d'une réponse rapide en cours
    readonly property bool paused: hoverPaused || replying

    property var current: null         // notification affichée (la plus récente du groupe)
    property var group: []             // notifications affichées ensemble, la plus récente en dernier
    property var queue: []             // en attente de popup

    // historique, le plus récent en premier :
    // { uid, notif, time, icon, appName, summary, body, critical, seen, stale }
    property var history: []
    readonly property int historyCap: 50

    // non vues : reçues en Ne pas déranger, ou retirées de la file sans
    // avoir été affichées. Remis à zéro à l'ouverture du centre de contrôle.
    readonly property int unread: {
        let c = 0
        for (const e of history)
            if (!e.seen)
                c++
        return c
    }

    // groupes repliés dans le centre de contrôle (clé "jour|application")
    property var collapsedGroups: ({})

    property int _uid: 0

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        inlineReplySupported: true

        onNotification: n => {
            n.tracked = true
            // un seul gestionnaire de fermeture par notif : purge file, groupe
            // et historique, et fait avancer la popup si c'était la courante
            n.closed.connect(() => root.onNotifClosed(n))
            // mise à jour sur place (replaces_id) : rafraîchir l'historique
            const refresh = () => root.refreshEntry(n)
            n.summaryChanged.connect(refresh)
            n.bodyChanged.connect(refresh)
            n.appIconChanged.connect(refresh)
            n.imageChanged.connect(refresh)
            n.urgencyChanged.connect(refresh)
            root.remember(n)

            if (root.peace && !(root.isCritical(n) && Settings.peaceAllowCritical)) {
                root.peaceMissed++
                return   // pas de popup, mais gardée (non vue) + action rejouable
            }
            root.enqueue(n)
        }
    }

    // ── utilitaires ─────────────────────────────────────────────────────────
    function isCritical(n) {
        return n !== null && n !== undefined && !n.synthetic
            && n.urgency === NotificationUrgency.Critical
    }

    function sameApp(a, b) {
        if (!a || !b || a.synthetic || b.synthetic)
            return false
        if (a.desktopEntry !== "" && a.desktopEntry === b.desktopEntry)
            return true
        return a.appName !== "" && a.appName === b.appName
    }

    function entryOf(n) {
        for (const e of history)
            if (e.notif === n)
                return e
        return null
    }

    function timeOf(n) {
        const e = entryOf(n)
        return e ? e.time : Date.now()
    }

    // actions affichables (l'action par défaut reste sur le clic)
    function visibleActions(n) {
        if (!n || n.synthetic)
            return []
        const out = []
        for (let i = 0; i < n.actions.length; i++) {
            const a = n.actions[i]
            if (a.identifier !== "default" && a.text !== "")
                out.push(a)
        }
        return out.slice(0, Settings.notifMaxActions)
    }

    // corps en texte riche NETTOYÉ pour Text.StyledText : on ne garde que
    // gras, italique, souligné, liens http(s) et retours à la ligne ; tout le
    // reste est échappé (une app qui envoie « a < b » l'affiche tel quel)
    function richBody(text) {
        if (!text)
            return ""
        const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        const decode = s => s.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"")
                             .replace(/&apos;/g, "'").replace(/&#39;/g, "'").replace(/&amp;/g, "&")
        const tagRe = /<\/?([a-zA-Z]+)([^>]*)>/g
        let out = ""
        let last = 0
        let open = 0      // liens ouverts
        let m
        while ((m = tagRe.exec(text)) !== null) {
            out += esc(decode(text.slice(last, m.index)))
            last = tagRe.lastIndex
            const closing = m[0][1] === "/"
            const tag = m[1].toLowerCase()
            if (tag === "b" || tag === "i" || tag === "u")
                out += closing ? "</" + tag + ">" : "<" + tag + ">"
            else if (tag === "br")
                out += "<br>"
            else if (tag === "a") {
                if (closing) {
                    if (open > 0) { out += "</a>"; open-- }
                } else {
                    const href = /href\s*=\s*["']([^"']+)["']/i.exec(m[2])
                    if (href && /^https?:\/\//i.test(href[1])) {
                        out += "<a href=\"" + esc(href[1]) + "\">"
                        open++
                    }
                }
            }
            // autres balises (img, span…) : ignorées
        }
        out += esc(decode(text.slice(last)))
        while (open-- > 0)
            out += "</a>"
        return out.replace(/\n/g, "<br>")
    }

    // texte brut sur une ligne (balises retirées, entités décodées)
    function plainText(text) {
        if (!text)
            return ""
        return text.replace(/<br\s*\/?>/gi, " ").replace(/<[^>]*>/g, "").replace(/\n/g, " ")
            .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"")
            .replace(/&apos;/g, "'").replace(/&#39;/g, "'").replace(/&amp;/g, "&")
    }

    // « à l'instant », « il y a 5 min », « 14:32 », « hier, 14:32 »…
    // `now` est passé par l'appelant (Time.now) pour que la liaison se
    // réévalue chaque minute
    function ago(ms, now) {
        const n = now ? now.getTime() : Date.now()
        const s = Math.max(0, (n - ms) / 1000)
        if (s < 60)
            return "à l'instant"
        if (s < 3600)
            return "il y a " + Math.floor(s / 60) + " min"
        const d = new Date(ms)
        const hm = Qt.formatDateTime(d, "HH:mm")
        const label = dayLabel(ms, now)
        if (label === "Aujourd'hui")
            return hm
        if (label === "Hier")
            return "hier, " + hm
        return Qt.formatDateTime(d, "dd/MM") + ", " + hm
    }

    function dayLabel(ms, now) {
        const today = now ? new Date(now.getTime()) : new Date()
        today.setHours(0, 0, 0, 0)
        const d = new Date(ms)
        d.setHours(0, 0, 0, 0)
        const diff = Math.round((today - d) / 86400000)
        if (diff <= 0)
            return "Aujourd'hui"
        if (diff === 1)
            return "Hier"
        const s = d.toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM")
        return s.charAt(0).toUpperCase() + s.slice(1)
    }

    // ── popup : affichage, file, groupes ────────────────────────────────────
    function enqueue(n) {
        if (root.current === null) {
            show([n])
            return
        }
        // même application que la popup affichée (et rien de critique) :
        // on l'empile dans la même popup au lieu de faire la queue
        if (!isCritical(n) && !isCritical(root.current) && sameApp(root.current, n)) {
            root.group = root.group.concat([n])
            root.current = n
            if (root.popupShown)
                markSeen(n)
            startTimer()
            return
        }
        root.queue = root.queue.concat([n])
    }

    function show(list) {
        root.group = list
        root.current = list[list.length - 1]
        if (root.popupShown)
            for (const m of list)
                markSeen(m)
        startTimer()
    }

    function promoteNext() {
        hideTimer.stop()
        root.replying = false
        root.current = null
        root.group = []
        if (root.queue.length === 0)
            return
        const next = root.queue[0]
        let rest = root.queue.slice(1)
        let grp = [next]
        // les autres notifications de la même application attendant dans la
        // file partent avec elle
        if (!isCritical(next) && !next.synthetic) {
            grp = grp.concat(rest.filter(m => !isCritical(m) && sameApp(m, next)))
            rest = rest.filter(m => grp.indexOf(m) < 0)
        }
        root.queue = rest
        show(grp)
    }

    // ── chronomètre à échéance : vraie pause au survol ──────────────────────
    // (un Timer QML repart toujours de zéro ; on conserve donc nous-mêmes le
    //  temps restant pour le reprendre là où il s'était arrêté)
    property real totalMs: 0           // durée complète de la popup courante (0 = sans limite)
    property real remainingMs: 0
    property real deadlineMs: 0
    property int armCount: 0           // incrémenté à chaque (re)départ, pour la barre de temps
    readonly property bool timerRunning: hideTimer.running

    // la popup n'est RÉELLEMENT visible que si rien de plus prioritaire
    // (polkit, panneau) ne la masque. Le chronomètre est gelé tant qu'elle
    // est cachée, sinon une notif reçue derrière un panneau serait « avalée »
    // sans avoir été vue.
    readonly property bool popupShown: IslandState.globalView === "notification"

    function baseInterval() {
        return root.queue.length >= Settings.notifBurstThreshold
            ? Settings.notifBurstTimeout
            : Settings.notifTimeout
    }

    function startTimer() {
        hideTimer.stop()
        if (root.current === null)
            return
        if (isCritical(root.current)) {
            // reste affichée jusqu'à un clic ou la croix
            root.totalMs = 0
            root.remainingMs = 0
            return
        }
        root.totalMs = baseInterval()
        root.remainingMs = root.totalMs
        if (!root.paused && root.popupShown)
            armTimer(root.remainingMs)
    }

    function armTimer(ms) {
        root.deadlineMs = Date.now() + ms
        hideTimer.interval = Math.max(1, ms)
        hideTimer.restart()
        root.armCount++
    }

    function freeze() {
        if (hideTimer.running) {
            root.remainingMs = Math.max(0, root.deadlineMs - Date.now())
            hideTimer.stop()
        }
    }

    onPausedChanged: {
        if (root.current === null || root.totalMs === 0)
            return
        if (root.paused)
            freeze()
        else if (root.popupShown)
            armTimer(root.remainingMs)
    }

    // panneau/polkit passe devant → on gèle ; il se referme → on reprend
    onPopupShownChanged: {
        if (root.current === null)
            return
        if (!root.popupShown) {
            freeze()
        } else {
            for (const m of root.group)
                markSeen(m)
            if (!root.paused && root.totalMs > 0)
                armTimer(root.remainingMs)
        }
    }

    Timer {
        id: hideTimer
        repeat: false
        // expiration : on retire juste l'affichage, la notif reste dans
        // l'historique (et reste rejouable)
        onTriggered: root.promoteNext()
    }

    // ── actions sur la popup ────────────────────────────────────────────────
    function invokeDefault(n) {
        if (!n)
            return
        if (n.synthetic) {
            // résumé de fin de Ne pas déranger : ouvre l'historique
            IslandState.openCcPage("main")
            return
        }
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

    // clic gauche : ouvre (action par défaut de la plus récente), puis passe
    // à la suivante. Les notifs restent dans l'historique.
    function activateCurrent() {
        const n = root.current
        if (!n)
            return
        invokeDefault(n)
        // si l'action a déjà fermé la notif, onNotifClosed a déjà avancé
        if (root.current === n)
            promoteNext()
    }

    // croix : masque la popup sans rien supprimer
    function hideCurrent() {
        if (root.current)
            promoteNext()
    }

    // clic molette : ferme les notifs du groupe (et les retire de l'historique)
    function dismissCurrent() {
        if (!root.current)
            return
        if (root.current.synthetic) {
            promoteNext()
            return
        }
        for (const m of root.group.slice())
            m.dismiss()
    }

    // bouton d'action
    function invokeAction(n, action) {
        if (!n || !action)
            return
        action.invoke()
        if (root.current === n)
            promoteNext()
    }

    // réponse rapide
    function sendReply(n, text) {
        if (!n || n.synthetic || !n.hasInlineReply || text === "")
            return
        n.sendInlineReply(text)
        root.replying = false
        if (root.current === n)
            promoteNext()
    }

    // clic molette sur le compteur : vide la file d'un coup (les notifs
    // restent dans l'historique, non vues → pastille au repos)
    function clearQueue() {
        root.queue = []
        startTimer()
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
            uid: ++root._uid,
            notif: n,
            time: Date.now(),
            icon: iconFor(n),
            appName: n.appName,
            summary: n.summary,
            body: n.body,
            critical: isCritical(n),
            seen: false,
            stale: false,
        })
        // au-delà du cap, on ferme (et libère) les plus anciennes
        while (root.history.length > root.historyCap) {
            const old = root.history.pop()
            if (old.notif)
                old.notif.dismiss()
        }
        root.historyChanged()
    }

    function refreshEntry(n) {
        const e = entryOf(n)
        if (!e)
            return
        e.icon = iconFor(n)
        e.appName = n.appName
        e.summary = n.summary
        e.body = n.body
        e.critical = isCritical(n)
        root.historyChanged()
    }

    function markSeen(n) {
        const e = entryOf(n)
        if (e && !e.seen) {
            e.seen = true
            root.historyChanged()
        }
    }

    function markAllSeen() {
        let changed = false
        for (const e of root.history) {
            if (!e.seen) {
                e.seen = true
                changed = true
            }
        }
        if (changed)
            root.historyChanged()
    }

    // ouvrir le centre de contrôle = tout est vu
    readonly property bool controlOpen: IslandState.panel === "control"
    onControlOpenChanged: if (controlOpen) markAllSeen()

    // fermeture d'une notif (par son app, par dismiss(), ou au-delà du cap)
    function onNotifClosed(n) {
        if (root.queue.indexOf(n) >= 0)
            root.queue = root.queue.filter(m => m !== n)
        for (let i = 0; i < root.history.length; i++) {
            if (root.history[i].notif === n) {
                root.history.splice(i, 1)
                root.historyChanged()
                break
            }
        }
        if (root.group.indexOf(n) >= 0) {
            const rest = root.group.filter(m => m !== n)
            if (rest.length === 0) {
                promoteNext()
            } else {
                root.group = rest
                if (root.current === n)
                    root.current = rest[rest.length - 1]
            }
        }
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

    function removeEntries(entries) {
        for (const e of entries.slice())
            removeEntry(e)
    }

    function clearHistory() {
        const items = root.history.slice()
        root.history = []
        for (const e of items)
            if (e.notif)
                e.notif.dismiss()
    }

    // lignes à plat pour la liste du centre de contrôle :
    // { kind: "day", label } | { kind: "app", key, … } | { kind: "entry", entry }
    // regroupées par jour puis par application, dans l'ordre de récence
    function historyRows(now) {
        const days = []
        for (const e of root.history) {
            const label = dayLabel(e.time, now)
            let day = days.find(d => d.label === label)
            if (!day) {
                day = { label: label, apps: [] }
                days.push(day)
            }
            const appName = e.appName !== "" ? e.appName : "Autres"
            let app = day.apps.find(a => a.appName === appName)
            if (!app) {
                app = { appName: appName, entries: [] }
                day.apps.push(app)
            }
            app.entries.push(e)
        }
        const rows = []
        for (const day of days) {
            rows.push({ kind: "day", rid: "d|" + day.label, label: day.label })
            for (const app of day.apps) {
                const key = day.label + "|" + app.appName
                const stored = root.collapsedGroups[key]
                // par défaut, les gros groupes sont repliés
                const collapsed = stored !== undefined ? stored : app.entries.length > 3
                const withIcon = app.entries.find(e => e.icon !== "")
                rows.push({
                    kind: "app",
                    rid: "a|" + key,
                    key: key,
                    appName: app.appName,
                    icon: withIcon ? withIcon.icon : "",
                    count: app.entries.length,
                    latest: app.entries[0].time,
                    critical: app.entries.some(e => e.critical),
                    collapsed: collapsed,
                    entries: app.entries,
                })
                // replié : on montre quand même la plus récente
                const shown = collapsed ? app.entries.slice(0, 1) : app.entries
                for (const e of shown)
                    rows.push({ kind: "entry", rid: "e|" + e.uid, entry: e })
            }
        }
        return rows
    }

    function toggleGroup(key, currentlyCollapsed) {
        const c = Object.assign({}, root.collapsedGroups)
        c[key] = !currentlyCollapsed
        root.collapsedGroups = c
    }

    // ── Ne pas déranger ─────────────────────────────────────────────────────
    function togglePeace() {
        root.peace = !root.peace
    }

    onPeaceChanged: {
        if (root.peace) {
            root.peaceMissed = 0
            root.peaceSinceMs = Date.now()
            return
        }
        // sortie : résumé de ce qui est arrivé pendant ce temps
        if (root.peaceMissed > 0) {
            const counts = {}
            for (const e of root.history) {
                if (e.time < root.peaceSinceMs || e.stale)
                    continue
                const a = e.appName !== "" ? e.appName : "Autres"
                counts[a] = (counts[a] ?? 0) + 1
            }
            const parts = Object.keys(counts)
                .sort((a, b) => counts[b] - counts[a])
                .map(a => a + " (" + counts[a] + ")")
            const n = root.peaceMissed
            enqueue({
                synthetic: true,
                appName: "Ne pas déranger",
                appIcon: "",
                image: "",
                desktopEntry: "",
                summary: "Ne pas déranger terminé",
                body: n + (n > 1 ? " notifications : " : " notification : ") + parts.join(", "),
                urgency: NotificationUrgency.Normal,
                actions: [],
                hasInlineReply: false,
                inlineReplyPlaceholder: "",
                count: n,
            })
        }
        root.peaceMissed = 0
    }

    // plage automatique (Settings.peaceSchedule*) : on bascule seulement aux
    // BORDS de la plage, pour que le bouton manuel reste utilisable dedans
    function minutesOf(hhmm) {
        const p = hhmm.split(":")
        return parseInt(p[0]) * 60 + parseInt(p[1] ?? "0")
    }

    function inPeaceWindow() {
        if (!Settings.peaceScheduleEnabled)
            return false
        const d = new Date()
        const now = d.getHours() * 60 + d.getMinutes()
        const a = minutesOf(Settings.peaceScheduleStart)
        const b = minutesOf(Settings.peaceScheduleEnd)
        return a <= b ? (now >= a && now < b) : (now >= a || now < b)
    }

    property bool scheduleActive: false
    // « jusqu'à 08:00 » dans le centre de contrôle pendant la plage auto
    readonly property string peaceUntil: scheduleActive && peace ? Settings.peaceScheduleEnd : ""

    Timer {
        interval: 20000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            const inside = root.inPeaceWindow()
            if (inside !== root.scheduleActive) {
                root.scheduleActive = inside
                root.peace = inside
            }
        }
    }

    // ── historique conservé au redémarrage ──────────────────────────────────
    property bool historyLoaded: false

    FileView {
        id: historyFile
        path: Quickshell.statePath("notifications.json")
        printErrors: false
        blockLoading: true

        onLoaded: {
            try {
                const saved = JSON.parse(text())
                const restored = []
                for (const s of saved) {
                    restored.push({
                        uid: ++root._uid,
                        notif: null,
                        time: s.time,
                        icon: s.icon ?? "",
                        appName: s.appName ?? "",
                        summary: s.summary ?? "",
                        body: s.body ?? "",
                        critical: s.critical === true,
                        seen: s.seen !== false,
                        stale: true,
                    })
                }
                // les notifs reçues avant la fin du chargement restent devant
                root.history = root.history.concat(restored).slice(0, root.historyCap)
            } catch (e) {
                console.warn("Notifs : historique illisible, ignoré")
            }
            root.historyLoaded = true
        }
        onLoadFailed: root.historyLoaded = true   // pas encore de fichier
    }

    onHistoryChanged: if (historyLoaded && Settings.notifHistoryPersist) saveTimer.restart()

    Timer {
        id: saveTimer
        interval: 800
        onTriggered: {
            const out = root.history.map(e => ({
                time: e.time,
                icon: e.icon,
                appName: e.appName,
                summary: e.summary,
                body: e.body,
                critical: e.critical,
                seen: e.seen,
            }))
            historyFile.setText(JSON.stringify(out))
        }
    }
}
