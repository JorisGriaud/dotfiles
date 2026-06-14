pragma Singleton
import QtQuick
import Quickshell

/**
 * Recherche d'applications (fichiers .desktop) avec score de pertinence.
 */
Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values.filter(a => !a.noDisplay)

    function score(app, q) {
        const name = app.name.toLowerCase()
        if (name === q)
            return 100
        if (name.startsWith(q))
            return 90 - name.length * 0.1
        if (name.includes(" " + q))
            return 70
        if (name.includes(q))
            return 60

        const hay = (app.genericName + " " + app.comment + " "
                     + app.keywords.join(" ")).toLowerCase()
        if (hay.includes(q))
            return 35

        // sous-séquence : "ffx" trouve "firefox"
        let i = 0
        for (const ch of name) {
            if (i < q.length && ch === q[i])
                i++
        }
        if (i === q.length)
            return 20

        return 0
    }

    function query(q, limit) {
        q = q.trim().toLowerCase()
        if (q === "")
            return []
        return all.map(a => ({ app: a, s: score(a, q) }))
                  .filter(e => e.s > 0)
                  .sort((x, y) => y.s - x.s)
                  .slice(0, limit)
                  .map(e => e.app)
    }
}
