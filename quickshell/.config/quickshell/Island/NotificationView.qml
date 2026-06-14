import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.Config
import qs.Services

/**
 * Notification dans l'îlot : icône de l'application (ou initiale thémée),
 * titre et corps. Critique = accent rouge. Un clic n'importe où ferme
 * (géré par la MouseArea de fond d'Island.qml) ; le survol met le
 * chronomètre en pause (géré aussi par Island.qml).
 */
IslandView {
    id: root

    readonly property var n: Notifs.current
    readonly property bool critical: n ? n.urgency === NotificationUrgency.Critical : false
    readonly property color tone: critical ? Theme.critical : Theme.accent

    readonly property string iconSource: {
        if (!n)
            return ""
        if (n.image !== "")
            return n.image
        if (n.appIcon !== "")
            return Quickshell.iconPath(n.appIcon, true)
        return ""
    }

    implicitWidth: 430
    implicitHeight: Math.max(58, textCol.implicitHeight + 24)

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 14
        spacing: 12

        // icône d'app, ou initiale dans une pastille thémée
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            radius: 18
            color: Qt.alpha(root.tone, root.iconSource === "" ? 1.0 : 0.16)

            Text {
                anchors.centerIn: parent
                visible: root.iconSource === ""
                text: root.n ? (root.n.appName !== "" ? root.n.appName[0].toUpperCase() : "?") : ""
                color: Theme.islandBg
                font.family: Theme.fontFamily
                font.pixelSize: 17
                font.weight: Theme.fontWeightStrong
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 24
                visible: root.iconSource !== ""
                source: root.iconSource
            }
        }

        Column {
            id: textCol
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: 330
                elide: Text.ElideRight
                text: root.n?.summary ?? ""
                color: root.critical ? Theme.critical : Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                font.weight: Theme.fontWeightStrong
            }

            Text {
                width: 330
                visible: text !== ""
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                text: root.n?.body ?? ""
                textFormat: Text.PlainText
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }

    // liseré d'urgence
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 7
        height: 7
        radius: 3.5
        color: root.tone
    }
}
