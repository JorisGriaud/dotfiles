# 🏝️ Morphing Island — Quickshell

Îlot dynamique flottant pour Hyprland : une pilule unique en haut de l'écran qui
se transforme (morphing par ressorts critiquement amortis) en OSD, notification,
lanceur, calendrier, centre de contrôle, menu power ou invite Polkit.

> Projet **indépendant** de `~/.config/quickshell` (qui n'est pas modifié) :
> il se lance par chemin avec `qs -p`.

## Aperçu

**Au repos** — la pilule affiche l'heure :

![Repos](screenshots/01-rest.png)

**Au survol** — elle s'étend : médias · horloge · statuts système :

![Vue étendue](screenshots/05-expanded.png)

**OSD** (volume / luminosité) avec rond draggable, apparaît au changement :

![OSD volume](screenshots/02-osd-volume.png)

**Notifications** — normale et critique (accent rouge, délai allongé) :

![Notification](screenshots/03-notification.png)
![Notification critique](screenshots/04-notification-critical.png)

**Lanceur** — applications, calculatrice (`=`) et recherche de fichiers (`/`) :

![Lanceur applications](screenshots/13-launcher-apps.png)
![Calculatrice](screenshots/14-launcher-calc.png)
![Recherche de fichiers](screenshots/15-launcher-files.png)

**Centre de contrôle** — tuiles, sliders, média, historique des notifications :

![Centre de contrôle](screenshots/09-control-center.png)

Pages de détail — **Audio** (sorties/entrées + renommage ✎), **Réseau**, **Bluetooth** :

![Audio](screenshots/10-cc-audio.png)
![Réseau](screenshots/11-cc-network.png)
![Bluetooth](screenshots/12-cc-bluetooth.png)

**Calendrier** (clic sur l'horloge) et **menu power** (Tab/flèches, icônes seules) :

![Calendrier](screenshots/06-calendar.png)
![Menu power](screenshots/07-power.png)

## Lancement

```bash
qs -p ~/Documents/quickshell-ytb
```

Autostart Hyprland :

```ini
exec-once = qs -p ~/Documents/quickshell-ytb
exec-once = hyprsunset        # requis pour la tuile « Mode nuit »
```

> ⚠️ **Cohabitation avec une autre config** : deux services ne peuvent exister
> qu'une fois par session —
> - **Notifications** : si une autre config détient `org.freedesktop.Notifications`,
>   les notifications ne passent pas par l'îlot (un WARN le signale au lancement).
> - **Polkit** : pareil s'il y a déjà un agent graphique.

## Binds Hyprland recommandés

```ini
# Lanceur (raccourci global natif)
bind = SUPER, SPACE, global, island:launcher
# Menu power (éteindre / redémarrer / déconnexion)
bind = SUPER, ESCAPE, global, island:power
# Mode "Peace" (ne pas déranger)
bind = SUPER, N, global, island:peace

# Volume : wpctl suffit, PipeWire notifie l'îlot tout seul (OSD automatique)
bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindl  = , XF86AudioMute,        exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Luminosité : passer par l'IPC de l'îlot = OSD instantané
bindel = , XF86MonBrightnessUp,   exec, qs -p ~/Documents/quickshell-ytb ipc call island brightnessUp
bindel = , XF86MonBrightnessDown, exec, qs -p ~/Documents/quickshell-ytb ipc call island brightnessDown
```

Fonctions IPC : `toggleLauncher`, `toggleControlCenter`, `toggleCalendar`,
`togglePower`, `togglePeace`, `ccPage <network|audio|bluetooth>` (ouvre
directement une page du centre de contrôle), `volumeUp/Down`, `muteToggle`,
`brightnessUp/Down` — `qs -p ~/Documents/quickshell-ytb ipc show` pour la liste.

## Interactions

| Geste | Effet |
|---|---|
| Survol de la pilule | Extension : média \| grande horloge centrée \| statuts |
| Clic « dans le vide » | Épingle / désépingle l'îlot ouvert |
| Clic zone média ou statuts | Ouvre le **centre de contrôle** |
| Clic zone horloge | Ouvre le **calendrier** (‹ › ou ←/→ : mois, Échap : fermer) |
| Bouton ⏯ (zone média) | Lecture/pause sans toucher à l'épinglage |
| Notification : clic | Ouvre l'app / la page (action `default`) |
| Notification : clic **molette** | La ferme |
| Notification survolée | Chrono en pause ; en vue étendue elle s'affiche **en bas**, cloche = Peace |
| OSD volume/luminosité | **Rond draggable** ; le survol fige la disparition |
| Lanceur : `texte` | Recherche d'applications (flèches + Entrée) |
| Lanceur : `=2^10/3` | Calculatrice temps réel, Entrée copie |
| Lanceur : `/motif` | Recherche de fichiers dans `~` (fd), Entrée ouvre (xdg-open) |
| Menu power | ←/→ + Entrée, ou clic ; Échap ferme |
| Échap | Ferme lanceur / calendrier / centre de contrôle / power / Polkit |

## Centre de contrôle

Chaque tuile a deux zones : le **rond-icône** bascule le réglage, le **reste de
la tuile** ouvre sa page de détail (flèche retour / Échap pour remonter).
Un clic dans le vide ne ferme rien et ne vole jamais le focus.

- **Réseau** — en Ethernet : tuile `interface — IP privée`, page d'infos
  (interface, IP, débit) ; en Wi-Fi : SSID, page = liste des réseaux scannés
  (connexion au clic, `✓ %` de signal sur le réseau actif, mot de passe en
  ligne pour les réseaux inconnus, interrupteur dans l'en-tête).
- **Audio** — rond = sourdine ; page = **Sorties** (choix + volume) et
  **Entrées** (choix du micro + volume d'entrée).
- **Bluetooth** — rond = marche/arrêt (aussi en en-tête de la page) ;
  page = appareils avec actions « Connecter / Appairer », batterie si publiée.
- **Peace** (ne pas déranger) et **Mode nuit** (hyprsunset) : bascules simples.

Couleurs des ronds d'icônes des tuiles : `Theme.tileCircleOn/Off` et
`Theme.tileIconOn/Off` dans `Config/Theme.qml`.

Sliders volume/luminosité à rond draggable, carte média (pochette, ⏮ ⏯ ⏭,
volume), historique des notifications (croix par carte + « Tout effacer »).

## Architecture

```
quickshell-ytb/
├── shell.qml                  # Variants par écran + IPC + raccourcis globaux
├── Config/
│   ├── Theme.qml              # couleurs, typo (fontWeight = épaisseur globale !)
│   └── Settings.qml           # tailles, délais, préfixes =, /
├── Core/
│   └── CriticalSpring.qml     # ressort critiquement amorti EXACT
├── Services/                  # singletons système
│   ├── IslandState.qml        # états : panel (launcher/control/calendar/power) + OSD
│   ├── Audio.qml              # PipeWire (volume, mute, bascule de sortie)
│   ├── Brightness.qml         # sysfs + brightnessctl (setLive throttlé pour le drag)
│   ├── Media.qml              # MPRIS
│   ├── Network.qml            # wifi/ethernet (Quickshell.Networking)
│   ├── Battery.qml / Fan.qml  # UPower / hwmon
│   ├── Notifs.qml             # serveur, file, peace, historique, action default
│   ├── AppSearch.qml          # .desktop + scoring
│   ├── FileSearch.qml         # fd dans ~ (mode / du lanceur)
│   ├── NightLight.qml         # hyprsunset
│   ├── PolkitService.qml      # agent Polkit natif
│   └── Time.qml               # horloge + date du calendrier
├── Island/
│   ├── Island.qml             # LA fenêtre morphing (1/écran, mask, ressorts)
│   ├── IslandView.qml         # base des vues (fondu enchaîné)
│   ├── RestView.qml           # EQ + heure + volume
│   ├── ExpandedView.qml       # média | horloge centrée | statuts (+ notif en bas)
│   ├── OsdView.qml            # volume / luminosité, rond draggable
│   ├── NotificationView.qml   # clic = ouvrir, molette = fermer
│   ├── LauncherView.qml       # apps + =calc + /fichiers
│   ├── ControlCenterView.qml  # tuiles + média + historique notifs
│   ├── CalendarView.qml       # mois, jour actuel, navigation
│   ├── PowerView.qml          # éteindre / redémarrer / déconnexion
│   └── PolkitView.qml
├── Widgets/                   # EqBars, IslandButton, SlimBar, KnobSlider,
│                              # SpeakerVolume, ToggleTile
└── Icons/                     # 100 % vectoriel (QtQuick.Shapes, CurveRenderer)
    └── Wifi, Ethernet, Battery (iOS + éclair), Speaker, Sun, Moon, Fan, Media,
        Bell, Bluetooth, Power, Restart, Logout, Folder, File, Back, Search,
        Calc, Lock, Close, Bolt, Clipboard
```

### Typographie

Dans `Theme.qml` : `fontWeight` (texte courant) et `fontWeightStrong` (titres)
règlent l'**épaisseur** de toute l'interface sans toucher aux tailles —
descendre à 250/450 pour un rendu très fin, 400/700 pour du classique.

### Le moteur de morphing

`Core/CriticalSpring.qml` intègre la **solution analytique exacte** du ressort
critiquement amorti — zéro overshoot par construction, vitesse continue lors
d'un re-ciblage. Deux ressorts ciblent `implicitWidth/Height` de la vue
active : **changer de vue suffit à déclencher le morphing**.

### Multi-écrans

Un îlot par écran (`Variants`) ; les vues globales (OSD, notifications,
panneaux, Polkit) ne sortent que sur l'écran focalisé
(`Hyprland.focusedMonitor.name`).
