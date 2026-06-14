import QtQuick
import qs.Config

/**
 * Base de toutes les icônes vectorielles du shell.
 *
 * Les enfants dessinent dans un canevas logique de 24×24, mis à l'échelle
 * vers `size`. Les Shape doivent utiliser preferredRendererType: CurveRenderer
 * pour rester nets à n'importe quelle taille (rendu vectoriel GPU).
 *
 * Aucune police d'icônes : tout est Shape / Rectangle.
 */
Item {
    id: root

    property real size: 16
    property color color: Theme.fg
    property real strokeWidth: 1.9

    default property alias content: canvas.data

    implicitWidth: size
    implicitHeight: size

    Item {
        id: canvas
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
    }
}
