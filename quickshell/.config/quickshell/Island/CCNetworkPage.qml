import QtQuick
import Quickshell
import Quickshell.Networking as NM
import qs.Config
import qs.Services
import qs.Widgets
import qs.Icons

/**
 * Page Réseau du centre de contrôle.
 *  - En Ethernet : carte d'info (interface, IP privée, débit).
 *  - En Wi-Fi : liste des réseaux scannés, connexion au clic
 *    (mot de passe en ligne pour les réseaux sécurisés inconnus).
 */
Column {
    id: root

    property bool pageActive: false

    // réseau dont on attend le mot de passe (révèle le champ sous sa ligne)
    property var pskTarget: null

    spacing: 8

    onPageActiveChanged: {
        pskTarget = null
        if (Network.wifiDevice !== null)
            Network.wifiDevice.scannerEnabled = pageActive
        if (pageActive)
            Network.refreshIp()
    }

    // ── carte Ethernet ──────────────────────────────────────────────────────
    Rectangle {
        width: parent.width
        visible: Network.wiredConnected
        height: ethCol.implicitHeight + 22
        radius: 14
        color: Theme.surface

        Column {
            id: ethCol
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            spacing: 5

            Row {
                spacing: 10
                EthernetIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 17
                    color: Theme.accent
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Connexion filaire"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Theme.fontWeightStrong
                }
            }

            Repeater {
                model: [
                    { k: "Interface", v: Network.ifaceName },
                    { k: "Adresse IP", v: Network.ipAddress !== "" ? Network.ipAddress : "—" },
                    { k: "Débit", v: Network.wiredDevice !== null && Network.wiredDevice.linkSpeed > 0
                                     ? Network.wiredDevice.linkSpeed + " Mb/s" : "—" },
                ]
                delegate: Item {
                    required property var modelData
                    width: ethCol.width
                    height: 18

                    Text {
                        anchors.left: parent.left
                        text: modelData.k
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Theme.fontWeight
                    }
                    Text {
                        anchors.right: parent.right
                        text: modelData.v
                        color: Theme.fg
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Theme.fontWeight
                    }
                }
            }
        }
    }

    // ── Wi-Fi : liste des réseaux (l'interrupteur vit dans l'en-tête) ───────
    Text {
        visible: Network.wifiDevice !== null && NM.Networking.wifiEnabled && netRepeater.count === 0
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Recherche de réseaux…"
        color: Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Theme.fontWeight
    }

    Repeater {
        id: netRepeater

        // ScriptModel : recycle les delegates par identité — la liste ne se
        // reconstruit pas entièrement à chaque tick du scan
        model: ScriptModel {
            values: {
                if (Network.wifiDevice === null || !NM.Networking.wifiEnabled)
                    return []
                return [...Network.wifiDevice.networks.values]
                    .sort((a, b) => (b.connected - a.connected)
                                 || (b.signalStrength - a.signalStrength))
                    .slice(0, 8)
            }
        }

        delegate: Rectangle {
            id: netRow
            required property var modelData

            readonly property var net: modelData
            readonly property bool isOpen: net.security === NM.WifiSecurityType.Open

            width: parent.width
            height: 42
            radius: 12
            color: rowMouse.containsMouse ? Theme.surfaceHover
                 : netRow.net.connected ? Qt.alpha(Theme.accent, 0.18) : Theme.surface
            Behavior on color { ColorAnimation { duration: 110 } }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 12
                spacing: 10

                WifiIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 15
                    strength: Math.max(0, Math.min(1,
                        netRow.net.signalStrength > 1 ? netRow.net.signalStrength / 100
                                                      : netRow.net.signalStrength))
                    connected: true
                    color: netRow.net.connected ? Theme.accent : Theme.icon
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 230)
                    elide: Text.ElideRight
                    text: netRow.net.name
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: netRow.net.connected ? Theme.fontWeightStrong : Theme.fontWeight
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    const n = netRow.net
                    if (n.connected) {
                        const s = n.signalStrength > 1 ? n.signalStrength : n.signalStrength * 100
                        return "✓ " + Math.round(s) + "%"
                    }
                    if (n.stateChanging)
                        return "Connexion…"
                    return netRow.isOpen ? "Ouvert" : n.known ? "Enregistré" : "Sécurisé"
                }
                color: netRow.net.connected ? Theme.accent : Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall - 1
                font.weight: netRow.net.connected ? Theme.fontWeightStrong : Theme.fontWeight
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const n = netRow.net
                    if (n.connected)
                        n.disconnect()
                    else if (n.known || netRow.isOpen)
                        n.connect()
                    else
                        root.pskTarget = n   // demande de mot de passe
                }
            }
        }
    }

    // ── champ mot de passe (réseaux sécurisés inconnus) ─────────────────────
    // HORS du Repeater : sa durée de vie ne dépend pas des delegates,
    // que le scan détruit/recrée en permanence (sinon : frappe impossible)
    Rectangle {
        width: parent.width
        visible: root.pskTarget !== null
        height: 36
        radius: 12
        color: Theme.surface
        border.color: pskInput.activeFocus ? Theme.accent : Theme.islandBorder
        border.width: 1

        onVisibleChanged: {
            if (visible) {
                pskInput.text = ""
                pskInput.forceActiveFocus()
            }
        }

        TextInput {
            id: pskInput
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Theme.fontWeight
            clip: true

            onAccepted: {
                if (root.pskTarget !== null && text !== "") {
                    root.pskTarget.connectWithPsk(text)
                    root.pskTarget = null
                }
            }
            Keys.onEscapePressed: event => {
                root.pskTarget = null
                event.accepted = true   // ne pas fermer le panneau
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: pskInput.text === ""
                text: root.pskTarget !== null
                      ? `Mot de passe pour « ${root.pskTarget.name} » — Entrée : connexion`
                      : ""
                color: Theme.fgDim
                opacity: 0.7
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Theme.fontWeight
            }
        }
    }
}
