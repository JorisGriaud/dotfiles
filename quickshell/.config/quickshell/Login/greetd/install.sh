#!/usr/bin/env bash
# Installe le greeter Quickshell pour greetd (remplace SDDM).
#
#   sudo ./install.sh            installe / met à jour les fichiers, ne change PAS de gestionnaire
#   sudo ./install.sh --enable   idem + désactive SDDM et active greetd (effectif au prochain démarrage)
#   sudo ./install.sh --revert   revient à SDDM (le réinstalle s'il a été supprimé)
#
# À relancer (sans option) après chaque modif de ~/.config/quickshell :
# le greeter tourne sous l'utilisateur greetd, qui n'a pas accès à ton $HOME,
# donc il utilise une copie dans /etc/greetd/quickshell (liens Stow résolus
# avec rsync -L : les liens relatifs vers ~/dotfiles seraient cassés là-bas).
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Lance-le avec sudo."; exit 1; }
USER_NAME=${SUDO_USER:?Lance-le avec sudo depuis ton compte, pas depuis root}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
SRC=$(cd "$(dirname "$0")/../.." && pwd)
DEST=/etc/greetd/quickshell

if [[ ${1:-} == --revert ]]; then
    systemctl disable greetd.service || true
    rpm -q sddm >/dev/null || dnf install -y sddm
    systemctl enable sddm.service
    echo "SDDM réactivé. Redémarre pour revenir à l'ancien écran de connexion."
    exit 0
fi

echo "→ Paquets"
rpm -q greetd >/dev/null || dnf install -y greetd
rpm -q greetd-selinux >/dev/null || dnf install -y greetd-selinux || echo "  (greetd-selinux indisponible, on continue)"

GREETER_USER=$(grep -E '^\s*user\s*=' /etc/greetd/config.toml 2>/dev/null | head -1 | sed -E 's/.*"(.*)".*/\1/')
GREETER_USER=${GREETER_USER:-greetd}
id "$GREETER_USER" >/dev/null || { echo "Utilisateur $GREETER_USER introuvable."; exit 1; }
echo "  utilisateur du greeter : $GREETER_USER"

echo "→ Copie de la config Quickshell vers $DEST"
mkdir -p "$DEST"
rsync -aL --delete --no-owner --no-group \
    --exclude backup --exclude screenshots --exclude "*.tar" --exclude .git --exclude .claude \
    --exclude Login/wallpaper.jpg \
    "$SRC/" "$DEST/"

echo "→ Fond d'écran"
WALL=$(grep -m1 -E '^\s*path\s*=' "$USER_HOME/.config/hypr/hyprpaper.conf" 2>/dev/null | sed -E 's/^\s*path\s*=\s*//; s|^~|'"$USER_HOME"'|')
if [[ -n ${WALL:-} && -f $WALL ]]; then
    cp "$WALL" "$DEST/Login/wallpaper.jpg"
    echo "  $WALL"
else
    echo "  aucun trouvé dans hyprpaper.conf (fond uni)"
fi
chmod -R a+rX "$DEST"

echo "→ Photo de profil"
if [[ -f $USER_HOME/.face ]]; then
    mkdir -p /var/lib/AccountsService/icons /var/lib/AccountsService/users
    install -m 644 "$USER_HOME/.face" "/var/lib/AccountsService/icons/$USER_NAME"
    U=/var/lib/AccountsService/users/$USER_NAME
    [[ -f $U ]] || printf '[User]\n' > "$U"
    grep -q '^Icon=' "$U" && sed -i "s|^Icon=.*|Icon=/var/lib/AccountsService/icons/$USER_NAME|" "$U" \
        || echo "Icon=/var/lib/AccountsService/icons/$USER_NAME" >> "$U"
    echo "  ~/.face copiée"
else
    echo "  pas de ~/.face : l'initiale sera affichée"
fi

echo "→ Curseur"
if [[ -d $USER_HOME/.icons/Bibata-Modern-Classic && ! -d /usr/share/icons/Bibata-Modern-Classic ]]; then
    cp -r "$USER_HOME/.icons/Bibata-Modern-Classic" /usr/share/icons/
    echo "  Bibata-Modern-Classic copié dans /usr/share/icons"
fi

echo "→ Hyprland du greeter + config greetd"
install -m 644 "$SRC/Login/greetd/hyprland-greeter.lua" /etc/greetd/hyprland-greeter.lua
if [[ -f /etc/greetd/config.toml && ! -f /etc/greetd/config.toml.orig ]]; then
    cp /etc/greetd/config.toml /etc/greetd/config.toml.orig
fi
cat > /etc/greetd/config.toml <<EOF
[terminal]
vt = 1

[default_session]
command = "start-hyprland -- --config /etc/greetd/hyprland-greeter.lua"
user = "$GREETER_USER"
EOF

if [[ ${1:-} == --enable ]]; then
    echo "→ Bascule SDDM → greetd"
    systemctl disable sddm.service 2>/dev/null || true   # absent si SDDM est désinstallé
    systemctl enable greetd.service
    echo
    echo "C'est fait. Redémarre pour voir le nouveau greeter."
    echo "En cas d'écran noir : Ctrl+Alt+F3, connecte-toi, puis"
    echo "  sudo $SRC/Login/greetd/install.sh --revert && reboot"
    echo "Logs du greeter : /tmp/quickshell-greeter.log"
else
    echo
    echo "Fichiers installés. SDDM est toujours actif."
    echo "Pour basculer : sudo $0 --enable"
fi
