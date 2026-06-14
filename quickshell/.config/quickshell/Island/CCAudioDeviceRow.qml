import QtQuick
import qs.Config
import qs.Services
import qs.Icons

/**
 * Une ligne de périphérique audio (sortie ou entrée) du centre de contrôle :
 *   [ nom (ou alias)            ✎  ● ]
 * Cliquer la ligne sélectionne le périphérique ; le crayon le renomme
 * (saisie en ligne, Entrée valide, Échap annule).
 */
Rectangle {
    id: root

    property var node            // PwNode
    property bool current: false
    signal selected()

    property bool editing: false

    width: parent.width
    height: 40
    radius: 12
    color: rowMouse.containsMouse ? Theme.surfaceHover
         : current ? Qt.alpha(Theme.accent, 0.18) : Theme.surface
    Behavior on color { ColorAnimation { duration: 110 } }

    function beginEdit() {
        editing = true
        nameInput.text = AudioAliases.aliasOf(root.node) !== ""
                         ? AudioAliases.aliasOf(root.node)
                         : AudioAliases.label(root.node)
        nameInput.forceActiveFocus()
        nameInput.selectAll()
    }

    function commitEdit() {
        AudioAliases.setAlias(root.node.name, nameInput.text)
        editing = false
    }

    // libellé (mode affichage)
    Text {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: editBtn.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        visible: !root.editing
        elide: Text.ElideRight
        text: AudioAliases.label(root.node)
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.weight: root.current ? Theme.fontWeightStrong : Theme.fontWeight
    }

    // saisie (mode renommage)
    TextInput {
        id: nameInput
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: editBtn.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        visible: root.editing
        clip: true
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Theme.fontWeight

        onAccepted: root.commitEdit()
        Keys.onEscapePressed: event => {
            root.editing = false        // annule sans enregistrer
            event.accepted = true       // ne ferme pas le panneau
        }
    }

    // crayon (renommer)
    Item {
        id: editBtn
        anchors.right: dot.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 22

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: editMouse.containsMouse ? Qt.alpha(Theme.fg, 0.12) : "transparent"
        }

        EditIcon {
            anchors.centerIn: parent
            size: 14
            color: root.editing ? Theme.accent : Theme.fgDim
        }

        MouseArea {
            id: editMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.editing ? root.commitEdit() : root.beginEdit()
        }
    }

    // pastille de sélection
    Rectangle {
        id: dot
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 8
        height: 8
        radius: 4
        color: root.current ? Theme.accent : "transparent"
        border.color: root.current ? "transparent" : Theme.fgDim
        border.width: 1
    }

    // sélection du périphérique (clic sur la ligne, hors zones interactives)
    MouseArea {
        id: rowMouse
        anchors.left: parent.left
        anchors.right: editBtn.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        hoverEnabled: true
        enabled: !root.editing
        cursorShape: Qt.PointingHandCursor
        onClicked: root.selected()
    }
}
