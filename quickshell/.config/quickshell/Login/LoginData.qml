import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Données partagées par le greeter et l'écran de verrouillage :
 * comptes humains (/etc/passwd), nom d'hôte, fonds d'écran hyprpaper.
 *
 * Tout est lu en fichiers simples : ça marche aussi sous l'utilisateur
 * greetd, qui n'a pas accès à ton $HOME (les lectures échouent alors en
 * silence et on retombe sur les copies installées dans shellDir).
 */
Scope {
    id: root

    // [{ name, realName }] — uid 1000–59999 avec un vrai shell
    property var users: []
    property string hostname: ""
    // { "DP-1": "/chemin.jpg", … } d'après ~/.config/hypr/hyprpaper.conf
    property var wallpapers: ({})

    // photo de profil : ~/.face puis l'icône AccountsService (lisible par tous)
    function avatarSources(name: string): var {
        const home = Quickshell.env("USER") === name ? Quickshell.env("HOME") : "/home/" + name
        return [home + "/.face", "/var/lib/AccountsService/icons/" + name]
    }

    // fond d'un écran : celui d'hyprpaper pour cet écran, sinon n'importe
    // lequel d'hyprpaper, sinon la copie installée avec le greeter
    function wallpaperSources(screenName: string): var {
        const out = []
        if (wallpapers[screenName]) out.push(wallpapers[screenName])
        for (const k in wallpapers) if (out.indexOf(wallpapers[k]) < 0) out.push(wallpapers[k])
        out.push(Quickshell.shellDir + "/Login/wallpaper.jpg")
        return out
    }

    FileView {
        path: "/etc/passwd"
        onLoaded: {
            const list = []
            for (const line of text().split("\n")) {
                const f = line.split(":")
                if (f.length < 7) continue
                const uid = parseInt(f[2])
                if (uid < 1000 || uid >= 60000) continue
                if (/(nologin|false)$/.test(f[6])) continue
                list.push({ name: f[0], realName: f[4].split(",")[0] || f[0] })
            }
            root.users = list
        }
    }

    FileView {
        path: "/etc/hostname"
        onLoaded: root.hostname = text().trim()
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/hypr/hyprpaper.conf"
        printErrors: false
        onLoaded: {
            const map = {}
            const re = /wallpaper\s*\{([^}]*)\}/g
            let m
            while ((m = re.exec(text())) !== null) {
                const mon = /monitor\s*=\s*(\S*)/.exec(m[1])
                const p = /path\s*=\s*(.+)/.exec(m[1])
                if (p) map[mon ? mon[1] : "*"] = p[1].trim().replace(/^~/, Quickshell.env("HOME"))
            }
            root.wallpapers = map
        }
    }
}
