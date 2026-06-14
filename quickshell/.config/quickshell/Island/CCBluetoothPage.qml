import QtQuick
import Quickshell.Bluetooth
import qs.Config
import qs.Services
import qs.Widgets
import qs.Icons

/**
 * Page Bluetooth du centre de contrôle : interrupteur + appareils.
 * La découverte est active tant que la page est ouverte.
 */
Column {
    id: root

    property bool pageActive: false

    spacing: 8

    readonly property var adapter: Bluetooth.defaultAdapter

    onPageActiveChanged: {
        if (adapter !== null && adapter.enabled)
            adapter.discovering = pageActive
    }

    // l'interrupteur vit dans l'en-tête du panneau : si l'adaptateur est
    // (ré)activé pendant que la page est ouverte, relancer la découverte
    Connections {
        target: root.adapter
        function onEnabledChanged() {
            if (root.adapter.enabled && root.pageActive)
                root.adapter.discovering = true
        }
    }

    Text {
        visible: root.adapter === null
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Aucun adaptateur Bluetooth"
        color: Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Theme.fontWeight
    }

    Text {
        visible: root.adapter !== null && !root.adapter.enabled
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Bluetooth désactivé"
        color: Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Theme.fontWeight
    }

    Text {
        visible: root.adapter !== null && root.adapter.enabled && devRepeater.count === 0
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Recherche d'appareils…"
        color: Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Theme.fontWeight
    }

    Repeater {
        id: devRepeater
        model: {
            if (root.adapter === null || !root.adapter.enabled)
                return []
            return [...Bluetooth.devices.values]
                .filter(d => (d.deviceName !== "" || d.name !== ""))
                .sort((a, b) => (b.connected - a.connected)
                             || (b.paired - a.paired))
                .slice(0, 8)
        }

        delegate: Rectangle {
            id: devRow
            required property var modelData

            readonly property var dev: modelData
            readonly property string label:
                dev.deviceName !== "" ? dev.deviceName : dev.name

            width: parent.width
            height: 44
            radius: 12
            color: devMouse.containsMouse ? Theme.surfaceHover
                 : dev.connected ? Qt.alpha(Theme.accent, 0.18) : Theme.surface
            Behavior on color { ColorAnimation { duration: 110 } }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 12
                spacing: 10

                BluetoothIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 15
                    color: devRow.dev.connected ? Theme.accent : Theme.icon
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 220)
                    elide: Text.ElideRight
                    text: devRow.label
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: devRow.dev.connected ? Theme.fontWeightStrong : Theme.fontWeight
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // batterie de l'appareil s'il la publie
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: devRow.dev.batteryAvailable
                    text: Math.round(devRow.dev.battery * 100) + "%"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall - 1
                    font.weight: Theme.fontWeight
                }

                // libellé d'action, comme la maquette ("Connecter" cliquable)
                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    readonly property bool busy:
                        devRow.dev.state === BluetoothDeviceState.Connecting
                        || devRow.dev.state === BluetoothDeviceState.Disconnecting
                        || devRow.dev.pairing

                    text: devRow.dev.state === BluetoothDeviceState.Connecting ? "Connexion…"
                        : devRow.dev.state === BluetoothDeviceState.Disconnecting ? "Déconnexion…"
                        : devRow.dev.pairing ? "Appairage…"
                        : devRow.dev.connected ? "Connecté"
                        : devRow.dev.paired || devRow.dev.bonded ? "Connecter"
                        : "Appairer"
                    color: busy ? Theme.fgDim : Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall - 1
                    font.weight: Theme.fontWeight
                }
            }

            MouseArea {
                id: devMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const d = devRow.dev
                    if (d.connected)
                        d.disconnect()
                    else if (d.paired || d.bonded)
                        d.connect()
                    else
                        d.pair()
                }
            }
        }
    }
}
