import QtQuick

/**
 * Ressort critiquement amorti — solution analytique EXACTE, intégrée image par image.
 *
 *   x(t) = cible + (j0 + j1·t)·e^(−ω·t)      avec  j0 = x0 − cible,  j1 = v0 + ω·j0
 *
 * Contrairement à SpringAnimation, l'absence d'overshoot est garantie par les maths :
 * le mouvement est rapide, décélère naturellement et s'arrête net, sans rebond.
 * La vitesse est continue : re-cibler en plein vol reste parfaitement fluide.
 *
 * Usage :
 *   CriticalSpring { id: w; speed: 18; target: monItem.implicitWidth }
 *   width: w.value
 */
FrameAnimation {
    id: root

    // ω en rad/s : 10 = doux, 18 = vif (défaut), 28 = sec
    property real speed: 18
    property real target: 0
    property real value: 0
    property real velocity: 0

    // seuil de repos (unités de la valeur animée)
    property real restDelta: 0.05

    readonly property bool settled: !running

    running: false

    Component.onCompleted: snap()
    onTargetChanged: if (value !== target || velocity !== 0) start()

    // saute instantanément à la cible (ou à v), sans animation
    function snap(v) {
        if (v !== undefined)
            target = v
        value = target
        velocity = 0
        stop()
    }

    onTriggered: {
        // borne dt pour rester stable après un gel de frames (veille, lag)
        const dt = Math.min(frameTime, 1 / 30)
        const w = speed
        const j0 = value - target
        const j1 = velocity + w * j0
        const e = Math.exp(-w * dt)
        const drift = (j0 + j1 * dt) * e

        velocity = (j1 - w * (j0 + j1 * dt)) * e

        if (Math.abs(drift) < restDelta && Math.abs(velocity) < restDelta * w) {
            value = target
            velocity = 0
            stop()
        } else {
            value = target + drift
        }
    }
}
