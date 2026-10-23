import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Login

/**
 * Greeter greetd — point d'entrée séparé de shell.qml.
 *
 *   aperçu dans ta session :  qs -p ~/.config/quickshell/greeter.qml
 *   en vrai (via greetd)   :  voir Login/greetd/install.sh
 *
 * Une fenêtre par écran ; seul l'écran sous la souris porte le
 * formulaire et prend le clavier.
 */
ShellRoot {
    GreeterController { id: controller }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            property var modelData
            screen: modelData

            readonly property bool active: surface.active

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "black"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-greeter"
            WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            LoginSurface {
                id: surface
                anchors.fill: parent
                ctl: controller
                screenName: win.screen?.name ?? ""
            }
        }
    }
}
