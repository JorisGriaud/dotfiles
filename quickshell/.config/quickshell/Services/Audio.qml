pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * Volume de la sortie audio par défaut (PipeWire).
 * Tout changement (même externe : wpctl, molette…) déclenche l'OSD,
 * sauf pendant la phase d'armement au démarrage.
 */
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    // entrée par défaut (micro)
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real sourceVolume: source?.audio?.volume ?? 0
    readonly property bool sourceMuted: source?.audio?.muted ?? false

    // évite un OSD parasite à l'initialisation des bindings
    property bool armed: false

    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => n !== null)
    }

    Timer {
        interval: 1500
        running: true
        onTriggered: root.armed = true
    }

    Connections {
        target: root.sink?.audio ?? null
        // NB : le signal de notification de `volume` s'appelle bien volumesChanged
        function onVolumesChanged() { if (root.armed) IslandState.showOsd("volume") }
        function onMutedChanged() { if (root.armed) IslandState.showOsd("volume") }
    }

    function setVolume(v) {
        if (sink?.audio) {
            sink.audio.muted = false
            sink.audio.volume = Math.max(0, Math.min(1, v))
        }
    }

    function adjust(delta) {
        setVolume(volume + delta)
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted
    }

    function setSourceVolume(v) {
        if (source?.audio) {
            source.audio.muted = false
            source.audio.volume = Math.max(0, Math.min(1, v))
        }
    }

    function toggleSourceMute() {
        if (source?.audio)
            source.audio.muted = !source.audio.muted
    }

    // nom lisible de la sortie courante (tuile Audio du centre de contrôle),
    // alias personnalisé compris
    readonly property string sinkName: sink ? AudioAliases.label(sink) : "Aucune sortie"

    // bascule vers la sortie audio suivante
    function cycleSink() {
        const sinks = Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
        if (sinks.length < 2)
            return
        const cur = sinks.findIndex(n => n.id === root.sink?.id)
        Pipewire.preferredDefaultAudioSink = sinks[(cur + 1) % sinks.length]
    }
}
