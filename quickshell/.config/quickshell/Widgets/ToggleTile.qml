import QtQuick
import qs.Config

/**
 * Tuile du centre de contrôle, fidèle à la maquette :
 *   [ (icône dans un rond) Titre / sous-titre ]
 *
 * Le ROND est l'interrupteur (signal `toggled`) ; le reste de la tuile
 * ouvre la page de détail (`opened`) quand `hasPage` est vrai, sinon
 * il bascule aussi. L'icône enfant doit lire `contentColor`.
 */
Rectangle {
    id: root

    property bool active: false
    property string title: ""
    property string subtitle: ""
    property bool hasPage: false

    signal toggled()
    signal opened()

    // l'icône est posée SUR le rond : couleurs réglables dans Theme.qml
    // (tileCircleOn/Off pour le rond, tileIconOn/Off pour l'icône)
    readonly property color circleColor: active ? Theme.tileCircleOn : Theme.tileCircleOff
    readonly property color contentColor: active ? Theme.tileIconOn : Theme.tileIconOff
    readonly property color titleColor: active ? Theme.islandBg : Theme.fg
    readonly property color subColor: active ? Qt.alpha(Theme.islandBg, 0.72) : Theme.fgDim

    default property alias iconContent: iconSlot.data

    implicitHeight: 52
    radius: 26
    color: active ? Theme.accent
         : bodyMouse.containsMouse ? Theme.surfaceHover : Theme.surface
    Behavior on color { ColorAnimation { duration: Theme.fadeDuration } }

    // corps de la tuile : page de détail (ou bascule s'il n'y en a pas)
    MouseArea {
        id: bodyMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.hasPage ? root.opened() : root.toggled()
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 9
        anchors.right: parent.right
        anchors.rightMargin: 10
        spacing: 10

        // le rond-interrupteur
        Rectangle {
            id: circle
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            radius: 17
            color: root.circleColor
            scale: circleMouse.containsMouse ? 1.08 : 1.0
            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.fadeDuration } }

            Item {
                id: iconSlot
                anchors.centerIn: parent
                width: 20
                height: 20
            }

            MouseArea {
                id: circleMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggled()
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - circle.width - parent.spacing
            spacing: 0

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.title
                color: root.titleColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Theme.fontWeightStrong
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                visible: text !== ""
                text: root.subtitle
                color: root.subColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall - 1
                font.weight: Theme.fontWeight
            }
        }
    }
}
