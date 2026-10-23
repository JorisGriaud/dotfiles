import QtQuick
import Quickshell
import Quickshell.Services.Pam

/**
 * Logique de l'écran de verrouillage : même interface que
 * GreeterController, mais un seul compte (le tien) et PAM pour vérifier.
 */
Scope {
    id: root

    signal unlocked()
    signal escapePressed()   // Échap sur un champ vide (ferme l'aperçu)

    readonly property string mode: "lock"

    readonly property alias loginData: dataObj
    readonly property var user: {
        const me = Quickshell.env("USER")
        return dataObj.users.find(u => u.name === me) ?? { name: me, realName: me }
    }
    readonly property var users: [user]
    readonly property int userIndex: 0
    readonly property var sessions: []
    readonly property var session: null

    property bool busy: false
    property string errorText: ""
    property int failCount: 0
    property string statusText: ""

    readonly property string activeScreen: cursor.screenName

    // vrai quand l'écran est affiché (verrouillé ou aperçu) : le suivi de
    // la souris ne tourne pas le reste du temps
    property bool running: false

    CursorScreen { id: cursor; enabled: root.running }

    property string pending: ""

    function selectUser(i: int): void {}
    function nextSession(): void {}
    function power(action: string): void {}
    function quitDemo(): void { escapePressed() }

    function reset(): void {
        if (pam.active) pam.abort()
        pending = ""
        busy = false
        errorText = ""
    }

    function submit(password: string): void {
        if (busy) return
        errorText = ""
        busy = true
        pending = password
        pam.user = user.name
        if (!pam.start()) fail("PAM indisponible")
    }

    function fail(msg: string): void {
        pending = ""
        busy = false
        errorText = msg
        failCount++
    }

    LoginData { id: dataObj }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellDir + "/Login/pam"
        config: "password"

        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.pending)
                root.pending = ""
            }
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.busy = false
                root.unlocked()
            } else {
                root.fail("Mot de passe incorrect")
            }
        }
        onError: err => root.fail("Erreur PAM : " + PamError.toString(err))
    }
}
