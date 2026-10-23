# ❄️ Joris' Dotfiles : Hyprland & Quickshell

Mes fichiers de configuration sous **Fedora Linux 44**, autour du compositeur **Hyprland** (Wayland) et d'une interface entièrement écrite en **Quickshell** : barre, notifications, lanceur, menu d'alimentation, écran de verrouillage et même l'écran de connexion.

L'objectif : un bureau fluide, piloté au clavier, avec une seule charte graphique partout.

![Aperçu du bureau](quickshell/.config/quickshell/screenshots/00-overview.png)

---

## 🏝️ Pièce maîtresse : Morphing Island

La barre est un **îlot dynamique flottant** codé from scratch en QML : une pilule
unique en haut de l'écran qui **se transforme** (morphing par ressorts physiques
*critically damped*, sans rebond) en OSD, notification, lanceur, calculatrice,
calendrier, centre de contrôle, menu power ou invite Polkit. Toutes les icônes
sont **vectorielles** (aucune police d'icônes).

| Vue étendue | Centre de contrôle |
|---|---|
| ![Étendue](quickshell/.config/quickshell/screenshots/05-expanded.png) | ![Centre de contrôle](quickshell/.config/quickshell/screenshots/09-control-center.png) |

➡️ **[Documentation complète, galerie et raccourcis de l'îlot](quickshell/.config/quickshell/README.md)**

### Connexion et verrouillage

Le même code Quickshell fournit aussi :

* **l'écran de connexion**, lancé par [greetd](https://sr.ht/~kennylevinsen/greetd/) à la place de SDDM : grande horloge, avatar, champ du mot de passe, choix de la session. Sur deux écrans, le formulaire suit la souris ;
* **l'écran de verrouillage** (Super+L), avec exactement le même visuel.

Les fichiers sont dans [`quickshell/.config/quickshell/Login/`](quickshell/.config/quickshell/Login/), avec le point d'entrée [`greeter.qml`](quickshell/.config/quickshell/greeter.qml).

---

## 🚀 Ce que j'utilise

| Rôle | Outil |
|---|---|
| OS | Fedora Linux 44 |
| Compositeur | [Hyprland](https://hyprland.org/) 0.56, configuration en **Lua** |
| Barre, notifications, lanceur, OSD, menu power, agent Polkit | [Quickshell](https://quickshell.outfoxxed.me/) : la Morphing Island |
| Écran de verrouillage | Quickshell (`Login/LockScreen.qml`) |
| Écran de connexion | greetd + greeter Quickshell |
| Fond d'écran | hyprpaper |
| Mode nuit | hyprsunset (tuile du centre de contrôle) |
| Terminal | [Kitty](https://sw.kovidgoyal.net/kitty/), police JetBrainsMono Nerd Font |
| Shell | [Fish](https://fishshell.com/) |
| Gestionnaire de fichiers | [Thunar](https://docs.xfce.org/xfce/thunar/start), et [Yazi](https://yazi-rs.github.io/) dans le terminal |
| Navigateur | Firefox |
| Captures d'écran | grim + slurp + swappy |
| Thème GTK | BouziProNa-Dark, icônes Papirus-Dark |
| Curseur | Bibata-Modern-Classic |
| Polices | Inter (interface), JetBrains Mono (code) |
| Gestion des dotfiles | GNU Stow |

## 🎨 Palette de couleurs

L'interface Quickshell et le thème GTK partagent la même palette, inspirée de Tailwind et définie dans [`Config/Theme.qml`](quickshell/.config/quickshell/Config/Theme.qml) :

| Rôle | Couleur |
|---|---|
| Fond | `#1a1d23` |
| Surface / cartes | `#2f343a` |
| Accent | `#3b82f6` |
| Succès / actif | `#3bb77e` |
| Danger | `#ef4444` |

## ⌨️ Raccourcis principaux

| Raccourci | Action |
|---|---|
| `Super + T` | Terminal (Kitty) |
| `Super + Q` | Fermer la fenêtre |
| `Super + A` | Lanceur de l'îlot |
| `Super + N` | Centre de contrôle |
| `Super + Suppr` | Menu d'alimentation (éteindre, redémarrer, déconnexion) |
| `Super + L` | Verrouiller l'écran |
| `Super + R` | Panneau de rafraîchissement (shell, réseau, son…) |
| `Super + Shift + R` | Relancer Quickshell (si l'îlot est figé) |
| `Super + E` | Thunar |
| `Super + B` | Firefox |
| `Super + V` | Fenêtre flottante |
| `Super + S` / `Super + Shift + S` | Afficher / envoyer vers l'espace spécial |
| `Super + 1…0` / `Super + Shift + 1…0` | Changer d'espace / y déplacer la fenêtre |
| `Alt + S` | Capture d'une zone, annotée dans swappy |

## 📂 Structure du dépôt

Chaque dossier est un paquet **GNU Stow** qui reproduit l'arborescence de destination.

```text
.
├── fish/          # ~/.config/fish/
├── gtk/           # ~/.themes/            (BouziProNa)
├── hyprland/      # ~/.config/hypr/       (config Lua + hyprpaper)
├── kitty/         # ~/.config/kitty/
├── quickshell/    # ~/.config/quickshell/ ← îlot, greeter et verrouillage
├── wallpapers/    # ~/Images/Wallpapers/
└── yazi/          # ~/.config/yazi/
```

## 🛠️ Installation

**1. Dépendances**
```bash
sudo dnf copr enable errornointernet/quickshell
sudo dnf install stow git hyprland hyprpaper hyprsunset quickshell \
                 kitty fish Thunar yazi firefox grim slurp swappy wl-clipboard \
                 brightnessctl fd-find rsms-inter-fonts jetbrains-mono-fonts \
                 papirus-icon-theme
```
> Dépendances propres à l'îlot (réseau, audio, batterie, Bluetooth, Polkit) :
> voir le [README de la Morphing Island](quickshell/.config/quickshell/README.md#-installation).

**2. Cloner le dépôt**
```bash
git clone git@github.com:jorisgriaud/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

**3. Déployer les configurations**
```bash
stow hyprland quickshell kitty fish yazi gtk wallpapers
```
Le curseur Bibata-Modern-Classic n'est pas dans le dépôt : installe-le dans `~/.icons/`.

**4. Écran de connexion (greetd)**
```bash
sudo ~/.config/quickshell/Login/greetd/install.sh            # installe greetd et copie le greeter
sudo ~/.config/quickshell/Login/greetd/install.sh --enable   # active greetd (et désactive SDDM s'il est installé)
```
Le greeter tourne sous l'utilisateur `greetd`, qui n'a pas accès à `$HOME` : le script en copie une version dans `/etc/greetd/quickshell`, avec le fond d'écran et l'avatar (`~/.face`). **Relance-le sans option après chaque modification de la config Quickshell.**

Si l'écran de connexion ne s'affiche pas au démarrage : `Ctrl+Alt+F3`, connecte-toi, puis consulte `/tmp/quickshell-greeter.log` et `journalctl -b -u greetd`.

Pour revenir à SDDM : `sudo ~/.config/quickshell/Login/greetd/install.sh --revert` (SDDM est réinstallé s'il a été supprimé).

## ⚙️ Notes techniques (Hyprland 0.55+)

Hyprland est configuré en **Lua** (`hyprland.lua` + `modules/*.lua`). Les dispatchers s'écrivent donc en syntaxe Lua, par exemple pour la déconnexion du menu power :

```bash
hyprctl dispatch 'hl.dsp.exit()'
```

Pour piloter l'îlot depuis un script :

```bash
qs ipc call island toggleLauncher
qs ipc call lock lock
```
