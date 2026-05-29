# ❄️ Joris' Dotfiles : Hyprland & Quickshell

Bienvenue dans mes fichiers de configuration ! Ce dépôt centralise mon environnement de travail sous **Fedora Linux**, construit autour du gestionnaire de fenêtres **Hyprland** (Wayland) et de composants développés sur mesure avec **Quickshell**. 

L'objectif de ce "rice" est d'offrir un flux de travail fluide, orienté clavier, tout en maintenant une esthétique cohérente et moderne basée sur une palette de couleurs Tailwind CSS personnalisée.

![Screenshot Placeholder](lien_vers_une_image_de_ton_bureau.png)

---

## 🚀 Composants Principaux

* **OS :** Fedora Linux
* **Window Manager :** [Hyprland](https://hyprland.org/) *(Compatible v0.55+ avec la nouvelle syntaxe IPC Lua)*
* **Barre d'état :** [Quickshell](https://quickshell.outfoxxed.me/) *(Codée en QML, intégrant l'horloge système native et le dispatch Hyprland)*
* **Menu de déconnexion :** [Wlogout](https://github.com/ArtsyMacaw/wlogout)
* **Thème GTK :** Fork personnalisé de [Orchis-Theme](https://github.com/vinceliuice/Orchis-theme)
* **Gestionnaire de connexion :** SDDM
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
├── gtk/           # ~/.themes/
├── hyprland/      # ~/.config/hypr/
├── quickshell/    # ~/.config/quickshell/
├── sddm/          # /etc/sddm.conf.d/ & /usr/share/sddm/themes/
├── wallpapers/    # ~/Pictures/Wallpapers/
└── wlogout/       # ~/.config/wlogout/
```

## 🛠️ Installation & Déploiement

Pour cloner et appliquer cette configuration sur une nouvelle installation Fedora :

**1. Installer les dépendances requises**
```bash
sudo dnf install stow git hyprland sddm
# Assurez-vous d'avoir installé Quickshell selon la documentation officielle
```

**2. Cloner le dépôt**
```bash
git clone git@github.com:JorisGriaud/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

**3. Déployer les configurations utilisateur**
Utilisez Stow pour créer les liens symboliques dans votre répertoire personnel :
```bash
stow hyprland
stow quickshell
stow wlogout
stow gtk
stow cursor
stow wallpapers
```

**4. Déployer la configuration système (SDDM)**
Comme SDDM réside à la racine du système, une commande spécifique avec les privilèges administrateur est requise :
```bash
sudo stow -t / sddm
```

## ⚙️ Notes Techniques (Hyprland 0.55+)

La barre Quickshell incluse dans ce dépôt est spécifiquement codée pour supporter le nouveau moteur Lua d'Hyprland (introduit dans la version 0.55). Les interactions de changement d'espace de travail utilisent le dispatcher natif structuré :

```qml
// Exemple d'IPC implémenté dans le shell.qml
onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + " })")
```
