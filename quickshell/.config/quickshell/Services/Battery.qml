pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

/**
 * Batterie (UPower). `percentage` est sur l'échelle 0–100, normalisée ici en 0–1.
 */
Singleton {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property bool available: dev !== null && dev.ready && dev.isLaptopBattery
    readonly property real level: dev ? dev.percentage / 100 : 0
    readonly property bool charging: dev !== null
        && (dev.state === UPowerDeviceState.Charging
         || dev.state === UPowerDeviceState.FullyCharged
         || dev.state === UPowerDeviceState.PendingCharge)
    readonly property bool low: !charging && level <= 0.20
}
