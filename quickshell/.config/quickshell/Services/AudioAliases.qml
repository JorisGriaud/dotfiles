pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Noms personnalisés des périphériques audio (sorties / entrées).
 * La correspondance nom-de-nœud PipeWire → alias est persistée en JSON dans
 * le répertoire d'état, donc conservée d'une session à l'autre.
 */
Singleton {
    id: root

    property var map: ({})

    FileView {
        id: file
        path: Quickshell.statePath("audio-aliases.json")
        printErrors: false   // le fichier n'existe pas au premier lancement
        onLoaded: {
            try {
                root.map = JSON.parse(text()) || {}
            } catch (e) {
                root.map = {}
            }
        }
        Component.onCompleted: reload()
    }

    // libellé à afficher : alias si défini, sinon description, sinon nom brut
    function label(node) {
        if (!node)
            return ""
        const a = root.map[node.name]
        if (a !== undefined && a !== "")
            return a
        return node.description !== "" ? node.description : node.name
    }

    // l'utilisateur a-t-il défini un alias pour ce nœud ?
    function aliasOf(node) {
        if (!node)
            return ""
        return root.map[node.name] ?? ""
    }

    function setAlias(nodeName, alias) {
        if (!nodeName)
            return
        const m = Object.assign({}, root.map)
        const trimmed = alias.trim()
        if (trimmed === "")
            delete m[nodeName]
        else
            m[nodeName] = trimmed
        root.map = m
        file.setText(JSON.stringify(m))
    }
}
