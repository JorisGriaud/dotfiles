pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

/**
 * Lecteur MPRIS "actif" : le premier en lecture, sinon le premier disponible.
 */
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var active: players.find(p => p.isPlaying)
                               ?? (players.length > 0 ? players[0] : null)

    readonly property bool hasPlayer: active !== null
    readonly property bool playing: active?.isPlaying ?? false
    readonly property string title: active?.trackTitle ?? ""
    readonly property string artist: active?.trackArtist ?? ""
    readonly property string artUrl: active?.trackArtUrl ?? ""

    function togglePlaying() {
        if (active?.canTogglePlaying)
            active.togglePlaying()
    }

    function next() {
        if (active?.canGoNext)
            active.next()
    }

    function previous() {
        if (active?.canGoPrevious)
            active.previous()
    }
}
