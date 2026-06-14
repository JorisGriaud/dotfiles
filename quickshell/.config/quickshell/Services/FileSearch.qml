pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Recherche de fichiers dans le home (mode "/" du lanceur).
 * `fd` respecte .gitignore et ignore les fichiers cachés par défaut.
 *
 * Les exécutions sont sérialisées par Quickshell ; un jeton FIFO par
 * lancement permet d'ignorer la sortie tardive d'un fd tué (sinon elle
 * écraserait les résultats de la requête suivante, ou la liste vidée).
 */
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    property string query: ""
    property var results: []   // { name, dir, path }

    property int reqId: 0      // dernier jeton demandé
    property var pending: []   // jetons des fd lancés, dans l'ordre (FIFO)

    function search(q) {
        query = q.trim()
        debounce.restart()
    }

    function open(path) {
        Quickshell.execDetached(["xdg-open", path])
    }

    Timer {
        id: debounce
        interval: 130
        onTriggered: {
            proc.running = false   // annule la recherche précédente
            if (root.query === "") {
                root.pending = []  // sa sortie tardive sera ignorée
                root.results = []
                return
            }
            root.reqId++
            root.pending.push(root.reqId)
            proc.command = ["fd", "--type", "f", "-i",
                            "--max-results", "40", "--", root.query]
            proc.running = true
        }
    }

    Process {
        id: proc
        workingDirectory: root.home
        stdout: StdioCollector {
            onStreamFinished: {
                // les fins de processus arrivent dans l'ordre de lancement
                const myId = root.pending.length > 0 ? root.pending.shift() : -1
                if (myId !== root.reqId)
                    return   // exécution annulée ou remplacée : on jette

                const out = []
                for (const line of this.text.split("\n")) {
                    if (line === "")
                        continue
                    const slash = line.lastIndexOf("/")
                    out.push({
                        name: slash >= 0 ? line.slice(slash + 1) : line,
                        dir: "~/" + (slash >= 0 ? line.slice(0, slash) : ""),
                        path: root.home + "/" + line,
                    })
                }
                // tri : les chemins courts (moins profonds) d'abord
                out.sort((a, b) => a.path.length - b.path.length)
                root.results = out
            }
        }
    }
}
