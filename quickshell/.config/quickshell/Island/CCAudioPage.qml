import QtQuick
import Quickshell.Services.Pipewire
import qs.Config
import qs.Services
import qs.Widgets
import qs.Icons

/**
 * Page Audio du centre de contrôle, fidèle à la maquette :
 *   Sorties : choix du périphérique + volume
 *   Entrées : choix du micro + volume d'entrée
 */
Column {
    id: root

    property bool pageActive: false

    spacing: 8

    readonly property var sinks:
        Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio !== null)
    readonly property var sources:
        Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio !== null)

    // ── Sorties ─────────────────────────────────────────────────────────────
    Text {
        text: "Sorties"
        color: Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Theme.fontWeightStrong
    }

    Repeater {
        model: root.sinks

        delegate: CCAudioDeviceRow {
            required property var modelData
            node: modelData
            current: Pipewire.defaultAudioSink !== null
                     && modelData.id === Pipewire.defaultAudioSink.id
            onSelected: Pipewire.preferredDefaultAudioSink = modelData
        }
    }

    // volume de sortie
    FatSlider {
        width: parent.width
        value: Audio.volume
        fillColor: Audio.muted ? Theme.fgDim : Theme.accent
        onMoved: v => Audio.setVolume(v)

        SpeakerIcon {
            anchors.centerIn: parent
            size: 15
            volume: Audio.volume
            muted: Audio.muted
            color: Theme.islandBg
        }
    }

    // ── Entrées ─────────────────────────────────────────────────────────────
    Text {
        visible: root.sources.length > 0
        text: "Entrées"
        color: Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Theme.fontWeightStrong
    }

    Repeater {
        model: root.sources

        delegate: CCAudioDeviceRow {
            required property var modelData
            node: modelData
            current: Pipewire.defaultAudioSource !== null
                     && modelData.id === Pipewire.defaultAudioSource.id
            onSelected: Pipewire.preferredDefaultAudioSource = modelData
        }
    }

    // volume d'entrée (micro)
    FatSlider {
        width: parent.width
        visible: root.sources.length > 0
        value: Audio.sourceVolume
        fillColor: Audio.sourceMuted ? Theme.fgDim : Theme.accent
        onMoved: v => Audio.setSourceVolume(v)

        MicIcon {
            anchors.centerIn: parent
            size: 15
            muted: Audio.sourceMuted
            color: Theme.islandBg
        }
    }
}
