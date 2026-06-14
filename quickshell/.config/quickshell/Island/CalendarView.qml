import QtQuick
import qs.Config
import qs.Services
import qs.Widgets
import qs.Icons

/**
 * Petit calendrier mensuel (clic sur l'horloge de la vue étendue).
 * Jour actuel en pastille accent ; chevrons pour changer de mois.
 * Échap (ou clic dans le vide) referme.
 */
IslandView {
    id: root

    // premier jour du mois affiché
    property var shownMonth: new Date(Time.now.getFullYear(), Time.now.getMonth(), 1)

    readonly property int cellSize: 30

    onActiveChanged: {
        if (active) {
            shownMonth = new Date(Time.now.getFullYear(), Time.now.getMonth(), 1)
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 80
        onTriggered: keys.forceActiveFocus()
    }

    Item {
        id: keys
        focus: root.active
        Keys.onEscapePressed: IslandState.closePanel()
        Keys.onLeftPressed: root.changeMonth(-1)
        Keys.onRightPressed: root.changeMonth(1)
    }

    function changeMonth(delta) {
        shownMonth = new Date(shownMonth.getFullYear(), shownMonth.getMonth() + delta, 1)
    }

    readonly property string monthLabel: {
        const s = shownMonth.toLocaleDateString(Qt.locale("fr_FR"), "MMMM yyyy")
        return s.charAt(0).toUpperCase() + s.slice(1)
    }

    // grille : décalage du 1er du mois (semaine commençant lundi)
    readonly property int firstOffset: (shownMonth.getDay() + 6) % 7
    readonly property int daysInMonth:
        new Date(shownMonth.getFullYear(), shownMonth.getMonth() + 1, 0).getDate()
    readonly property bool isCurrentMonth:
        shownMonth.getFullYear() === Time.now.getFullYear()
        && shownMonth.getMonth() === Time.now.getMonth()

    implicitWidth: 7 * cellSize + 2 * 22
    implicitHeight: col.implicitHeight + 26

    Column {
        id: col
        anchors.top: parent.top
        anchors.topMargin: 13
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 7

        // ── en-tête : ‹ Mois Année › ────────────────────────────────────────
        Item {
            width: 7 * root.cellSize
            height: 28

            IslandButton {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 26
                implicitHeight: 26
                onClicked: root.changeMonth(-1)
                BackIcon { anchors.centerIn: parent; size: 14; color: Theme.fgDim }
            }

            Text {
                anchors.centerIn: parent
                text: root.monthLabel
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                font.weight: Theme.fontWeightStrong
            }

            IslandButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 26
                implicitHeight: 26
                onClicked: root.changeMonth(1)
                BackIcon {
                    anchors.centerIn: parent
                    size: 14
                    color: Theme.fgDim
                    rotation: 180
                }
            }
        }

        // ── initiales des jours ─────────────────────────────────────────────
        Row {
            Repeater {
                model: ["L", "M", "M", "J", "V", "S", "D"]
                delegate: Item {
                    required property string modelData
                    width: root.cellSize
                    height: 18
                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall - 1
                        font.weight: Theme.fontWeight
                    }
                }
            }
        }

        // ── grille des jours ────────────────────────────────────────────────
        Grid {
            columns: 7

            Repeater {
                model: root.firstOffset + root.daysInMonth
                delegate: Item {
                    required property int index
                    readonly property int day: index - root.firstOffset + 1
                    readonly property bool isToday:
                        root.isCurrentMonth && day === Time.now.getDate()

                    width: root.cellSize
                    height: root.cellSize

                    Rectangle {
                        anchors.centerIn: parent
                        width: root.cellSize - 5
                        height: root.cellSize - 5
                        radius: width / 2
                        visible: isToday
                        color: Theme.accent
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: day >= 1
                        text: day
                        color: isToday ? Theme.islandBg : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: isToday ? Theme.fontWeightStrong : Theme.fontWeight
                    }
                }
            }
        }
    }
}
