import QtQuick

/**
 * Image qui essaie une liste de chemins dans l'ordre et passe au suivant
 * si le fichier est absent ou illisible. `failed` = aucun n'a marché.
 */
Image {
    id: root

    property var sources: []
    property int index: 0
    readonly property bool failed: index >= sources.length

    onSourcesChanged: index = 0
    source: failed ? "" : "file://" + sources[index]
    onStatusChanged: if (status === Image.Error) index++

    asynchronous: true
    fillMode: Image.PreserveAspectCrop
}
