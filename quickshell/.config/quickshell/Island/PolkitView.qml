import QtQuick
import qs.Config
import qs.Services
import qs.Icons

/**
 * Demande d'élévation de privilèges (Polkit) directement dans l'îlot.
 * Entrée valide, Échap annule.
 */
IslandView {
    id: root

    readonly property var flow: PolkitService.flow

    implicitWidth: 470
    implicitHeight: col.implicitHeight + 30

    onActiveChanged: {
        if (active) {
            pw.text = ""
            focusTimer.restart()
        }
    }

    // nouveau flux d'authentification (objet AuthFlow différent)
    onFlowChanged: {
        if (active) {
            pw.text = ""
            focusTimer.restart()
        }
    }

    // mauvais mot de passe : PAM réutilise LE MÊME AuthFlow et émet
    // authenticationFailed() (flow ne change pas, donc onFlowChanged ne suffit
    // pas). On vide le champ pour la nouvelle tentative.
    Connections {
        target: root.flow
        function onAuthenticationFailed() {
            if (root.active) {
                pw.text = ""
                focusTimer.restart()
            }
        }
    }

    Timer {
        id: focusTimer
        interval: 80
        onTriggered: pw.forceActiveFocus()
    }

    Column {
        id: col
        anchors.top: parent.top
        anchors.topMargin: 15
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 56
        spacing: 9

        Row {
            spacing: 8

            LockIcon {
                anchors.verticalCenter: parent.verticalCenter
                size: 17
                color: Theme.accent
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Authentification requise"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                font.weight: Theme.fontWeightStrong
            }
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: root.flow?.message ?? ""
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }

        Text {
            width: parent.width
            visible: text !== ""
            wrapMode: Text.WordWrap
            text: root.flow?.supplementaryMessage ?? ""
            color: root.flow?.supplementaryIsError ? Theme.critical : Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }

        Rectangle {
            width: parent.width
            height: 34
            radius: 17
            color: Theme.surface
            border.color: pw.activeFocus ? Theme.accent : Theme.islandBorder
            border.width: 1

            TextInput {
                id: pw
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                clip: true

                onAccepted: PolkitService.submit(text)
                Keys.onEscapePressed: PolkitService.cancel()

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: pw.text === "" && !pw.activeFocus
                    text: root.flow?.inputPrompt !== "" ? (root.flow?.inputPrompt ?? "Mot de passe") : "Mot de passe"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Entrée : valider — Échap : annuler"
            color: Theme.fgDim
            opacity: 0.7
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall - 1
        }
    }
}
