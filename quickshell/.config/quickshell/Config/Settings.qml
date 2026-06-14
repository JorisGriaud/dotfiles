pragma Singleton
import QtQuick
import Quickshell

/**
 * Réglages de comportement — tailles, délais, options.
 */
Singleton {
    id: root

    // ── Géométrie de l'îlot ─────────────────────────────────────────────────
    // écart entre le bord supérieur de l'écran et la pilule. L'écart SOUS la
    // pilule (jusqu'à la fenêtre du dessous) vaut le `gaps_out` d'Hyprland :
    // pour un espacement vertical SYMÉTRIQUE, mets topMargin = ton gaps_out
    // (ici 12). Le contenu reste centré dans la pilule (pas de vide interne).
    readonly property int topMargin: 12
    // DOIT correspondre à ton `general:gaps_out` Hyprland : sert à viser le
    // BORD VISIBLE de la fenêtre du dessous (pas sa position interne), pour
    // que l'écart sous la pilule soit exactement égal à celui du dessus.
    readonly property int gapsOut: 10
    readonly property int restHeight: 38          // hauteur de la pilule au repos
    readonly property int expandedHeight: 56      // hauteur survolée
    readonly property int maxWidth: 600           // largeur du lanceur
    readonly property int contentPadding: 14      // marge interne horizontale

    // l'îlot réserve-t-il son espace (pousse les fenêtres) ? false = flotte au-dessus
    readonly property bool reserveSpace: true

    // ── Délais ──────────────────────────────────────────────────────────────
    readonly property int osdTimeout: 1500            // disparition de l'OSD
    readonly property int notifTimeout: 5000          // notification normale
    readonly property int notifCriticalTimeout: 12000 // notification critique
    readonly property int hoverCloseDelay: 180        // grâce avant re-réduction

    // ── Lanceur ─────────────────────────────────────────────────────────────
    readonly property int launcherMaxResults: 7
    readonly property string calcPrefix: "="
    readonly property string filePrefix: "/"

    // ── Divers ──────────────────────────────────────────────────────────────
    readonly property bool eqBarsEnabled: true    // barres d'égaliseur au repos
}
