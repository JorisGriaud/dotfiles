pragma Singleton
import QtQuick
import Quickshell

/**
 * Thème global — flat design, ombre subtile.
 * Toutes les icônes vectorielles lisent `accent` / `fg` : changer une couleur
 * ici recolore l'ensemble du shell.
 */
Singleton {
    id: root

    // ── Couleurs ────────────────────────────────────────────────────────────
    readonly property color islandBg: "#16161c"        // fond de la pilule
    readonly property color islandBorder: "#2a2a33"    // liseré discret
    readonly property color fg: "#e8e8ef"              // texte principal
    readonly property color fgDim: "#9a9aa8"           // texte secondaire
    readonly property color accent: "#8caaee"          // couleur d'accentuation
    readonly property color critical: "#e78284"        // notifications critiques
    readonly property color success: "#a6d189"         // éclair de charge, ok
    readonly property color surface: "#23232c"         // éléments posés sur la pilule
    readonly property color surfaceHover: "#2e2e3a"    // survol des boutons

    // ── Ombre ───────────────────────────────────────────────────────────────
    readonly property color shadowColor: Qt.rgba(0, 0, 0, 0.45)
    readonly property real shadowBlur: 22
    readonly property real shadowYOffset: 5

    // ── Typographie ─────────────────────────────────────────────────────────
    readonly property string fontFamily: "Inter, Cantarell, sans-serif"
    readonly property string monoFamily: "JetBrains Mono, monospace"
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeNormal: 13
    readonly property int fontSizeLarge: 17
    readonly property int fontSizeClock: 22

    // ── Ressorts (ω rad/s) ──────────────────────────────────────────────────
    readonly property real springFast: 26     // morphing de taille de l'îlot
    readonly property real springNormal: 18   // glissement des éléments
    readonly property real springSoft: 12     // jauges, remplissages

    // durée des fondus d'opacité (les fondus ne rebondissent pas, par nature)
    readonly property int fadeDuration: 140
}
