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
    readonly property color islandBg: "#1a1d23"        // fond de la pilule
    readonly property color islandBorder: "#2a2a33"    // liseré discret
    readonly property color fg: "#ffffff"              // texte principal
    readonly property color fgDim: "#5a5f64"           // texte secondaire
    readonly property color accent: "#3b82f6"          // couleur d'accentuation
    readonly property color secondary: "#60a5fa"
    readonly property color critical: "#ef4444"        // notifications critiques
    readonly property color success: "#3bb77e"         // éclair de charge, ok
    readonly property color surface: "#2f343a"         // éléments posés sur la pilule
    readonly property color surfaceHover: "#394c69"    // survol des boutons
    readonly property color icon: "#d6dade"            // icônes de statut neutres

    // ── Ronds des tuiles du centre de contrôle ──────────────────────────────
    // (le rond-interrupteur et son icône, selon l'état de la tuile)
    readonly property color tileCircleOn: "#60a5fa"    // rond, tuile active
    readonly property color tileIconOn: islandBg         // icône, tuile active
    readonly property color tileCircleOff: "#3a414b"   // rond, tuile inactive
    readonly property color tileIconOff: fg    // icône, tuile inactive

    // ── Menu power : couleur d'icône + liseré (sélection) par bouton ─────────
    readonly property color powerOff: "#ef4444"      // Éteindre
    readonly property color powerRestart: "#f59e0b"  // Redémarrer
    readonly property color powerLogout: "#3b82f6"   // Déconnexion

    // ── Ombre ───────────────────────────────────────────────────────────────
    readonly property color shadowColor: Qt.rgba(0, 0, 0, 0.45)
    readonly property real shadowBlur: 22
    readonly property real shadowYOffset: 5

    // ── Typographie ─────────────────────────────────────────────────────────
    readonly property string fontFamily: "Inter, Cantarell, sans-serif"
    readonly property string monoFamily: "JetBrains Mono, monospace"
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeNormal: 14
    readonly property int fontSizeLarge: 18
    readonly property int fontSizeClock: 20

    // épaisseur de police (100 fin … 900 gras), indépendante de la taille :
    // baisser fontWeight / fontWeightStrong affine tout le shell d'un coup
    readonly property int fontWeight: 350          // texte courant
    readonly property int fontWeightStrong: 550    // titres, heure, accents

    // ── Ressorts (ω rad/s) ──────────────────────────────────────────────────
    readonly property real springFast: 26     // morphing de taille de l'îlot
    readonly property real springNormal: 18   // glissement des éléments
    readonly property real springSoft: 12     // jauges, remplissages

    // durée des fondus d'opacité (les fondus ne rebondissent pas, par nature)
    readonly property int fadeDuration: 140
}
