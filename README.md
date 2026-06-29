# ❄️ Joris' Dotfiles : Hyprland & Quickshell

Bienvenue dans mes fichiers de configuration ! Ce dépôt centralise mon environnement de travail sous **Fedora Linux**, construit autour du gestionnaire de fenêtres **Hyprland** (Wayland) et de composants développés sur mesure avec **Quickshell**.

L'objectif de ce "rice" est d'offrir un flux de travail fluide, orienté clavier, tout en maintenant une esthétique cohérente et moderne basée sur une palette de couleurs Tailwind CSS personnalisée.

![Aperçu du bureau](quickshell/.config/quickshell/screenshots/00-overview.png)

---

## 🏝️ Pièce maîtresse — Morphing Island

La barre est un **îlot dynamique flottant** codé from scratch en QML : une pilule
unique en haut de l'écran qui **se transforme** (morphing par ressorts physiques
*critically damped*, sans rebond) en OSD, notification, lanceur, calculatrice,
calendrier, centre de contrôle, menu power ou invite Polkit. Toutes les icônes
sont **vectorielles** (aucune police d'icônes).

| Vue étendue | Centre de contrôle |
|---|---|
| ![Étendue](quickshell/.config/quickshell/screenshots/05-expanded.png) | ![Centre de contrôle](quickshell/.config/quickshell/screenshots/09-control-center.png) |

➡️ **[Documentation complète, galerie et raccourcis de l'îlot](quickshell/.config/quickshell/README.md)**

---

## 🚀 Composants Principaux

* **OS :** Fedora Linux
* **Window Manager :** [Hyprland](https://hyprland.org/) *(compatible v0.55+, nouvelle syntaxe IPC Lua)*
* **Barre d'état :** [Quickshell](https://quickshell.outfoxxed.me/) — la *Morphing Island* maison *(remplace progressivement waybar)*
* **Terminal :** [Kitty](https://sw.kovidgoyal.net/kitty/)
* **Shell :** [Fish](https://fishshell.com/)
* **Gestionnaire de fichiers :** [Thunar](https://docs.xfce.org/xfce/thunar/start)
* **Gestionnaire de fichiers (TUI) :** [Yazi](https://yazi-rs.github.io/)
* **Lanceur (secours) :** [Rofi](https://github.com/davatorium/rofi)
* **Menu de déconnexion :** [Wlogout](https://github.com/ArtsyMacaw/wlogout)
* **Thème GTK :** Fork personnalisé de [Orchis-Theme](https://github.com/vinceliuice/Orchis-theme)
* **Gestionnaire de connexion :** SDDM [pixie](https://github.com/xCaptaiN09/pixie-sddm)
* **Curseur :** Bibata-Modern-Classic
* **Gestionnaire de dotfiles :** GNU Stow

## 🎨 Palette de Couleurs (Tailwind Inspired)

L'ensemble du système (GTK, Quickshell, Wlogout) partage une charte graphique unifiée pour garantir une transition visuelle parfaite entre les applications :

* **Background :** `#1a1d23` (Noir profond)
* **Surface / Cards :** `#2f343a` (Gris anthracite)
* **Primary Accent :** `#3b82f6` (Bleu Tailwind)
* **Success / Active :** `#3bb77e` (Vert)
* **Destructive :** `#ef4444` (Rouge)

## 📂 Structure du Dépôt

La gestion des fichiers est assurée par **GNU Stow**, ce qui permet de conserver l'architecture exacte des dossiers cibles sans script d'installation complexe.

```text
.
├── cursor/        # ~/.local/share/icons/
├── fish/          # ~/.config/fish/
├── gtk/           # ~/.themes/
├── hyprland/      # ~/.config/hypr/
├── kitty/         # ~/.config/kitty/
├── quickshell/    # ~/.config/quickshell/   ← la Morphing Island
├── rofi/          # ~/.config/rofi/
├── sddm/          # /etc/sddm.conf.d/ & /usr/share/sddm/themes/
├── swaync/        # ~/.config/swaync/
├── waybar/        # ~/.config/waybar/
├── wallpapers/    # ~/Pictures/Wallpapers/
├── wlogout/       # ~/.config/wlogout/
└── yazi/          # ~/.config/yazi/
```

## 🛠️ Installation & Déploiement

Pour cloner et appliquer cette configuration sur une nouvelle installation Fedora :

**1. Installer les dépendances requises**
```bash
sudo dnf install stow git hyprland sddm kitty fish thunar rofi yazi \
                 brightnessctl fd-find wl-clipboard
# Quickshell : installez-le selon la documentation officielle
# (https://quickshell.outfoxxed.me/). hyprsunset est optionnel (mode nuit).
```
> Dépendances spécifiques à l'îlot (réseau, audio, batterie, Bluetooth, polkit) :
> voir le [README de la Morphing Island](quickshell/.config/quickshell/README.md#-installation).

**2. Cloner le dépôt**
```bash
git clone git@github.com:jorisgriaud/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

**3. Déployer les configurations utilisateur**
Utilisez Stow pour créer les liens symboliques dans votre répertoire personnel :
```bash
stow hyprland quickshell kitty fish rofi yazi wlogout gtk cursor wallpapers
```

**4. Déployer la configuration système (SDDM)**
Comme SDDM réside à la racine du système, une commande spécifique avec les privilèges administrateur est requise :
```bash
sudo stow -t / sddm
```

## ⚙️ Notes Techniques (Hyprland 0.55+)

La Morphing Island est spécifiquement codée pour supporter le nouveau moteur Lua d'Hyprland (introduit dans la version 0.55). Les interactions de changement d'espace de travail utilisent le dispatcher natif structuré :

```qml
// Exemple d'IPC implémenté dans le shell.qml
onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + " })")
```
