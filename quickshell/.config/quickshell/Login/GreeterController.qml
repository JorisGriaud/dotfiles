import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import Quickshell.Services.Pam

/**
 * Logique du greeter (greetd). Expose la même interface que
 * LockController, lue par LoginSurface.
 *
 * Hors greetd (lancé à la main dans ta session : `qs -p greeter.qml`),
 * on passe en mode « demo » : le mot de passe est vérifié par PAM,
 * les boutons d'alimentation ne font rien et Échap quitte.
 */
Scope {
    id: root

    readonly property string mode: Greetd.available ? "greeter" : "demo"

    readonly property alias loginData: dataObj
    readonly property var users: dataObj.users
    property int userIndex: 0
    readonly property var user: users[userIndex] ?? null

    // [{ id, name, exec, desktop }] depuis /usr/share/wayland-sessions
    property var sessions: []
    property int sessionIndex: 0
    readonly property var session: sessions[sessionIndex] ?? null

    property bool busy: false
    property string errorText: ""
    property int failCount: 0          // incrémenté à chaque échec → secousse
    property string statusText: ""     // message de réussite (démo)

    // écran qui porte le formulaire : celui où se trouve la souris
    readonly property string activeScreen: cursor.screenName

    CursorScreen { id: cursor }

    property string pending: ""

    function selectUser(i: int): void {
        if (busy || users.length === 0) return
        userIndex = (i + users.length) % users.length
        errorText = ""
    }

    function nextSession(): void {
        if (busy || sessions.length === 0) return
        sessionIndex = (sessionIndex + 1) % sessions.length
    }

    function submit(password: string): void {
        if (busy || !user) return
        errorText = ""
        busy = true
        pending = password
        if (mode === "greeter") {
            Greetd.createSession(user.name)
        } else {
            pam.user = user.name
            if (!pam.start()) fail("PAM indisponible")
        }
    }

    function fail(msg: string): void {
        pending = ""
        busy = false
        errorText = msg
        failCount++
    }

    function power(action: string): void {
        if (mode !== "greeter") {
            console.log("[greeter démo] action ignorée :", action)
            return
        }
        Quickshell.execDetached(["systemctl", action])
    }

    function quitDemo(): void {
        if (mode === "demo") Qt.quit()
    }

    function launch(): void {
        const s = session
        const cmd = s ? s.exec.split(/\s+/).filter(x => x.length > 0) : ["start-hyprland"]
        const desk = s && s.desktop ? s.desktop : (s ? s.name : "Hyprland")
        Greetd.launch(cmd, [
            "XDG_SESSION_TYPE=wayland",
            "XDG_CURRENT_DESKTOP=" + desk.replace(/;/g, ":").replace(/:$/, ""),
            "XDG_SESSION_DESKTOP=" + (s ? s.id : "hyprland")
        ], true)
    }

    LoginData { id: dataObj }

    // ── greetd ──────────────────────────────────────────────────────────────
    Connections {
        target: Greetd
        enabled: root.mode === "greeter"

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                Greetd.respond(root.pending)
                root.pending = ""
            } else if (error) {
                root.errorText = message
            }
        }
        function onAuthFailure(message) {
            if (Greetd.state !== GreetdState.Inactive) Greetd.cancelSession()
            root.fail("Mot de passe incorrect")
        }
        function onReadyToLaunch() { root.launch() }
        function onError(error) {
            if (Greetd.state !== GreetdState.Inactive) Greetd.cancelSession()
            root.fail(error)
        }
    }

    // ── mode démo : simple vérification PAM ─────────────────────────────────
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
                root.statusText = "Mot de passe correct, Hyprland démarrerait ici"
                quitTimer.start()
            } else {
                root.fail("Mot de passe incorrect")
            }
        }
        onError: err => root.fail("Erreur PAM : " + PamError.toString(err))
    }

    Timer {
        id: quitTimer
        interval: 2500
        onTriggered: Qt.quit()
    }

    // ── sessions disponibles ────────────────────────────────────────────────
    Process {
        running: true
        command: ["sh", "-c",
            "for f in /usr/share/wayland-sessions/*.desktop; do " +
            "grep -qiE '^(NoDisplay|Hidden)=true' \"$f\" && continue; " +
            "printf '%s\\t%s\\t%s\\t%s\\n' \"$(basename \"$f\" .desktop)\" " +
            "\"$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-)\" " +
            "\"$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2-)\" " +
            "\"$(grep -m1 '^DesktopNames=' \"$f\" | cut -d= -f2-)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = []
                for (const line of text.split("\n")) {
                    const f = line.split("\t")
                    if (f.length < 3 || !f[2]) continue
                    list.push({ id: f[0], name: f[1] || f[0], exec: f[2], desktop: f[3] || "" })
                }
                // Hyprland en premier
                list.sort((a, b) => (b.id === "hyprland") - (a.id === "hyprland"))
                root.sessions = list
            }
        }
    }
}
