import QtQuick
import Quickshell
import Quickshell.Widgets
// import qualifié : le type `Network` de ce module masquerait notre
// singleton Services/Network sinon
import Quickshell.Networking as NM
import Quickshell.Bluetooth
import qs.Config
import qs.Services
import qs.Widgets
import qs.Icons

/**
 * Centre de contrôle (clic sur les zones de la vue étendue).
 *
 * Chaque tuile a DEUX zones : le rond-icône bascule le réglage, le reste de
 * la tuile ouvre sa page de détail (réseau, audio, bluetooth). La flèche
 * retour / Échap remontent d'une page, puis ferment. Un clic dans le vide
 * ne ferme rien et ne perd pas le focus.
 */
IslandView {
    id: root

    readonly property int panelWidth: 440
    readonly property int pad: 16
    readonly property real tileWidth: (panelWidth - 2 * pad - 10) / 2

    // page courante : état GLOBAL (IslandState.ccPage), partagé entre les
    // instances par écran — "main" | "network" | "audio" | "bluetooth"
    readonly property string page: IslandState.ccPage

    implicitWidth: panelWidth
    implicitHeight: col.implicitHeight + 2 * pad - 4

    onActiveChanged: {
        if (active)
            focusTimer.restart()
    }

    function goBack() {
        if (IslandState.ccPage !== "main")
            IslandState.ccPage = "main"
        else
            IslandState.closePanel()
    }

    Timer {
        id: focusTimer
        interval: 80
        onTriggered: keys.forceActiveFocus()
    }

    // FocusScope englobant : quand un champ de saisie interne (renommage
    // audio, mot de passe Wi-Fi) se masque, le focus clavier revient au
    // scope — donc Échap referme toujours le panneau (pas de focus orphelin).
    FocusScope {
        id: keys
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: root.goBack()

    Column {
        id: col
        anchors.top: parent.top
        anchors.topMargin: root.pad - 4
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.panelWidth - 2 * root.pad
        spacing: 10

        // ── en-tête ─────────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 32

            IslandButton {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 28
                implicitHeight: 28
                baseColor: Theme.surface   // rond visible, comme la maquette
                onClicked: root.goBack()
                BackIcon { anchors.centerIn: parent; size: 16; color: Theme.fg }
            }

            Text {
                anchors.centerIn: parent
                text: root.page === "network" ? (Network.wiredConnected ? "Ethernet" : "Wi-Fi")
                    : root.page === "audio" ? "Audio"
                    : root.page === "bluetooth" ? "Bluetooth"
                    : "Centre de contrôle"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                font.weight: Theme.fontWeightStrong
            }

            // interrupteur de la page courante (comme la maquette)
            ToggleSwitch {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: (root.page === "network" && Network.wifiDevice !== null)
                      || (root.page === "bluetooth" && Bluetooth.defaultAdapter !== null)
                checked: root.page === "network"
                         ? NM.Networking.wifiEnabled
                         : (Bluetooth.defaultAdapter?.enabled ?? false)
                onToggled: {
                    if (root.page === "network")
                        NM.Networking.wifiEnabled = !NM.Networking.wifiEnabled
                    else if (Bluetooth.defaultAdapter !== null)
                        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                }
            }
        }

        // ════════ PAGE PRINCIPALE ════════
        Column {
            width: parent.width
            spacing: 10
            visible: root.page === "main"

            // ── tuiles ──────────────────────────────────────────────────────
            Grid {
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                // réseau : Ethernet (interface + IP privée) ou Wi-Fi (SSID)
                ToggleTile {
                    id: netTile
                    width: root.tileWidth
                    hasPage: true
                    title: Network.wiredConnected ? "Ethernet" : "Wi-Fi"
                    subtitle: Network.wiredConnected
                              ? Network.ifaceName + (Network.ipAddress !== "" ? " — " + Network.ipAddress : "")
                              : (Network.activeWifi?.name
                                 ?? (NM.Networking.wifiEnabled ? "Activé" : "Désactivé"))
                    active: Network.wiredConnected || NM.Networking.wifiEnabled
                    onOpened: IslandState.ccPage = "network"
                    onToggled: {
                        if (Network.wiredConnected)
                            IslandState.ccPage = "network"   // pas de bascule destructive en filaire
                        else
                            NM.Networking.wifiEnabled = !NM.Networking.wifiEnabled
                    }

                    EthernetIcon {
                        anchors.centerIn: parent
                        visible: Network.wiredConnected
                        size: 18
                        color: netTile.contentColor
                    }
                    WifiIcon {
                        anchors.centerIn: parent
                        visible: !Network.wiredConnected
                        size: 18
                        strength: Network.strength
                        connected: Network.wifiConnected
                        color: netTile.contentColor
                    }
                }

                ToggleTile {
                    id: audioTile
                    width: root.tileWidth
                    hasPage: true
                    title: "Audio"
                    subtitle: Audio.sinkName
                    active: !Audio.muted
                    onOpened: IslandState.ccPage = "audio"
                    onToggled: Audio.toggleMute()
                    SpeakerIcon {
                        anchors.centerIn: parent
                        size: 18
                        volume: Audio.volume
                        muted: Audio.muted
                        color: audioTile.contentColor
                    }
                }

                ToggleTile {
                    id: btTile
                    width: root.tileWidth
                    hasPage: true
                    title: "Bluetooth"
                    subtitle: {
                        const adapter = Bluetooth.defaultAdapter
                        if (adapter === null)
                            return "Indisponible"
                        if (!adapter.enabled)
                            return "Désactivé"
                        const dev = Bluetooth.devices.values.find(d => d.connected)
                        return dev ? (dev.deviceName !== "" ? dev.deviceName : dev.name) : "Activé"
                    }
                    active: Bluetooth.defaultAdapter?.enabled ?? false
                    onOpened: IslandState.ccPage = "bluetooth"
                    onToggled: {
                        const adapter = Bluetooth.defaultAdapter
                        if (adapter !== null)
                            adapter.enabled = !adapter.enabled
                    }
                    BluetoothIcon {
                        anchors.centerIn: parent
                        size: 18
                        color: btTile.contentColor
                    }
                }

                ToggleTile {
                    id: peaceTile
                    width: root.tileWidth
                    title: "Peace"
                    subtitle: Notifs.peace ? "Ne pas déranger" : "Notifications actives"
                    active: Notifs.peace
                    onToggled: Notifs.togglePeace()
                    BellIcon {
                        anchors.centerIn: parent
                        size: 17
                        silenced: Notifs.peace
                        color: peaceTile.contentColor
                    }
                }

                /*ToggleTile {
                    id: nightTile
                    width: root.tileWidth
                    title: "Mode nuit"
                    subtitle: NightLight.active ? "Activé" : "Désactivé"
                    active: NightLight.active
                    onToggled: NightLight.toggle()
                    MoonIcon {
                        anchors.centerIn: parent
                        size: 17
                        color: nightTile.contentColor
                    }
                }*/
            }

            // ── volume / luminosité : barres épaisses façon maquette ────────
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

            // luminosité (PC portables)
            FatSlider {
                width: parent.width
                visible: Brightness.available
                value: Brightness.level
                onMoved: v => Brightness.setLive(v)
                onReleased: v => Brightness.set(v)

                SunIcon {
                    anchors.centerIn: parent
                    size: 15
                    level: Brightness.level
                    color: Theme.islandBg
                }
            }

            // ── carte média ─────────────────────────────────────────────────
            ClippingRectangle {
                width: parent.width
                height: 118
                radius: 16
                color: Theme.surface
                visible: Media.hasPlayer

                Image {
                    anchors.fill: parent
                    source: Media.artUrl
                    visible: Media.artUrl !== ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                // voile sombre pour la lisibilité
                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(Theme.islandBg, Media.artUrl !== "" ? 0.62 : 0)
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: mediaButtons.left
                    anchors.rightMargin: 8
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    spacing: 1

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: Media.title !== "" ? Media.title : "Sans titre"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Theme.fontWeightStrong
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: Media.artist
                        visible: Media.artist !== ""
                        color: Qt.alpha(Theme.fg, 0.7)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Theme.fontWeight
                    }
                }

                Row {
                    id: mediaButtons
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    spacing: 2

                    IslandButton {
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: Media.active?.canGoPrevious ?? false
                        onClicked: Media.previous()
                        MediaIcon { anchors.centerIn: parent; kind: "prev"; size: 15; color: Theme.fg }
                    }

                    IslandButton {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 36
                        implicitHeight: 36
                        enabled: Media.active?.canTogglePlaying ?? false
                        onClicked: Media.togglePlaying()
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Theme.accent
                        }
                        MediaIcon {
                            anchors.centerIn: parent
                            kind: Media.playing ? "pause" : "play"
                            size: 18
                            color: Theme.islandBg
                        }
                    }

                    IslandButton {
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: Media.active?.canGoNext ?? false
                        onClicked: Media.next()
                        MediaIcon { anchors.centerIn: parent; kind: "next"; size: 15; color: Theme.fg }
                    }
                }

                // volume de sortie, draggable
                KnobSlider {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    knobSize: 12
                    value: Audio.volume
                    fillColor: Audio.muted ? Theme.fgDim : Theme.accent
                    trackColor: Qt.alpha(Theme.fg, 0.18)
                    onMoved: v => Audio.setVolume(v)
                }
            }

            // ── notifications ───────────────────────────────────────────────
            Item {
                width: parent.width
                height: 24

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Notifications"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Theme.fontWeightStrong
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Tout effacer"
                    visible: Notifs.history.length > 0
                    color: clearMouse.containsMouse ? Theme.accent : Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Theme.fontWeight

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.clearHistory()
                    }
                }
            }

            Text {
                visible: Notifs.history.length === 0
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Aucune notification"
                color: Theme.fgDim
                opacity: 0.7
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Theme.fontWeight
            }

            ListView {
                id: historyList
                width: parent.width
                height: Math.min(contentHeight, 232)
                visible: Notifs.history.length > 0
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds

                model: ScriptModel {
                    values: Notifs.history
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: historyList.width
                    height: cardRow.implicitHeight + 18
                    radius: 12
                    color: cardMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                    Behavior on color { ColorAnimation { duration: 110 } }

                    // clic = ouvrir (action par défaut de la notif),
                    // clic molette = retirer de l'historique.
                    // Déclaré en premier → sous le contenu et la croix.
                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouseEvent => {
                            if (mouseEvent.button === Qt.MiddleButton)
                                Notifs.removeEntry(modelData)
                            else
                                Notifs.activateEntry(modelData)
                        }
                    }

                    Row {
                        id: cardRow
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 34
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        // icône de l'application, sinon pastille initiale
                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 26
                            height: 26

                            // chargement SYNCHRONE : avec asynchronous + anchors.fill,
                            // le recalcul de sourceSize relance le chargement en boucle
                            // et status reste bloqué sur Loading
                            IconImage {
                                id: histIcon
                                anchors.fill: parent
                                source: modelData.icon ?? ""
                                visible: (modelData.icon ?? "") !== "" && status === Image.Ready
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 13
                                visible: !histIcon.visible
                                color: modelData.critical ? Theme.critical : Theme.secondary

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.appName !== "" ? modelData.appName[0].toUpperCase() : "?"
                                    color: Theme.islandBg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Theme.fontWeightStrong
                                }
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 36
                            spacing: 1

                            Item {
                                width: parent.width
                                height: 15

                                Text {
                                    anchors.left: parent.left
                                    text: modelData.appName
                                    color: modelData.critical ? Theme.critical : Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    font.weight: Theme.fontWeight
                                }

                                Text {
                                    anchors.right: parent.right
                                    text: modelData.time
                                    color: Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    font.weight: Theme.fontWeight
                                }
                            }

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: modelData.summary
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Theme.fontWeightStrong
                            }

                            Text {
                                width: parent.width
                                visible: text !== ""
                                elide: Text.ElideRight
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                text: modelData.body
                                textFormat: Text.PlainText
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Theme.fontWeight
                            }
                        }
                    }

                    // croix de suppression (comme la maquette)
                    IslandButton {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        implicitWidth: 22
                        implicitHeight: 22
                        onClicked: Notifs.removeEntry(modelData)
                        CloseIcon { anchors.centerIn: parent; size: 11; color: Theme.fgDim }
                    }
                }
            }
        }

        // ════════ PAGES DE DÉTAIL ════════
        // pageActive est dérivé de l'état GLOBAL (et non de root.active) :
        // les deux instances par écran écrivent ainsi les mêmes valeurs dans
        // scannerEnabled/discovering au lieu de se les disputer quand le
        // focus change d'écran pendant qu'une page est ouverte.
        CCNetworkPage {
            width: parent.width
            visible: root.page === "network"
            pageActive: IslandState.panel === "control" && IslandState.ccPage === "network"
        }

        CCAudioPage {
            width: parent.width
            visible: root.page === "audio"
            pageActive: IslandState.panel === "control" && IslandState.ccPage === "audio"
        }

        CCBluetoothPage {
            width: parent.width
            visible: root.page === "bluetooth"
            pageActive: IslandState.panel === "control" && IslandState.ccPage === "bluetooth"
        }
    }
    }
}
